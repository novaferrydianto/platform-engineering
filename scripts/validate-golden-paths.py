#!/usr/bin/env python3
"""Validate every golden path: template schema, skeleton wiring, security posture.

A broken template only fails when a developer tries to use it in the portal, so
this runs in CI instead.
"""

from __future__ import annotations

import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

ROOT = Path(__file__).resolve().parent.parent
GOLDEN_PATHS = ROOT / "golden-paths"

errors: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def validate_template(path: Path) -> dict:
    doc = yaml.safe_load(path.read_text(encoding="utf-8"))
    rel = path.relative_to(ROOT)

    check(doc.get("kind") == "Template", f"{rel}: kind must be Template")

    _VALID_API_VERSIONS = (
        "scaffolder.backstage.io/v1beta3",
    )
    check(
        doc.get("apiVersion") in _VALID_API_VERSIONS,
        f"{rel}: apiVersion must be one of {_VALID_API_VERSIONS}",
    )

    metadata = doc.get("metadata") or {}
    for field in ("name", "title", "description"):
        check(bool(metadata.get(field)), f"{rel}: metadata.{field} is required")

    spec = doc.get("spec") or {}
    check(bool(spec.get("owner")), f"{rel}: spec.owner is required")
    check(bool(spec.get("parameters")), f"{rel}: spec.parameters is required")

    steps = spec.get("steps") or []
    check(bool(steps), f"{rel}: spec.steps is required")

    actions = [s.get("action") for s in steps]
    check("fetch:template" in actions, f"{rel}: must render its skeleton with fetch:template")
    check(
        "catalog:register" in actions,
        f"{rel}: must register the new component with catalog:register",
    )

    # A scaffolded repo with no branch protection is a hole in the paved road.
    for step in steps:
        if step.get("action") == "publish:github":
            inputs = step.get("input") or {}
            check(
                inputs.get("protectDefaultBranch") is not False,
                f"{rel}: publish:github must not disable protectDefaultBranch",
            )
            check(
                inputs.get("repoVisibility") == "private",
                f"{rel}: publish:github should create private repositories",
            )

    return doc


def validate_skeleton(directory: Path) -> None:
    rel = directory.relative_to(ROOT)

    catalog_info = directory / "catalog-info.yaml"
    check(catalog_info.is_file(), f"{rel}: skeleton must contain catalog-info.yaml")

    ci = directory / ".github" / "workflows" / "ci.yml"
    check(ci.is_file(), f"{rel}: skeleton must contain .github/workflows/ci.yml")

    if ci.is_file():
        text = ci.read_text(encoding="utf-8")
        check(
            "platform-engineering/.github/workflows/reusable-" in text,
            f"{rel}: ci.yml must call the platform's reusable workflows, not inline its own logic",
        )
        # GitHub expressions must be escaped or the scaffolder consumes them.
        for line in text.splitlines():
            stripped = line.strip()
            if "${{" not in stripped or stripped.startswith("#"):
                continue
            if "${{ values." in stripped or "${{ '${{" in stripped:
                continue
            if "${{ github." in stripped or "${{ needs." in stripped:
                errors.append(
                    f"{rel}/.github/workflows/ci.yml: unescaped GitHub expression "
                    f"consumed by the scaffolder: {stripped}"
                )

    dockerfile = directory / "Dockerfile"
    if dockerfile.is_file():
        text = dockerfile.read_text(encoding="utf-8")
        check("USER " in text, f"{rel}/Dockerfile: must drop to a non-root USER")

    values = directory / "helm" / "values.yaml"
    if values.is_file():
        config = yaml.safe_load(values.read_text(encoding="utf-8")) or {}
        security = config.get("securityContext") or {}
        pod_security = config.get("podSecurityContext") or {}
        check(
            security.get("allowPrivilegeEscalation") is False,
            f"{rel}/helm/values.yaml: securityContext.allowPrivilegeEscalation must be false",
        )
        check(
            security.get("readOnlyRootFilesystem") is True,
            f"{rel}/helm/values.yaml: securityContext.readOnlyRootFilesystem must be true",
        )
        check(
            pod_security.get("runAsNonRoot") is True,
            f"{rel}/helm/values.yaml: podSecurityContext.runAsNonRoot must be true",
        )
        check(
            (config.get("networkPolicy") or {}).get("enabled") is True,
            f"{rel}/helm/values.yaml: networkPolicy must be enabled by default",
        )


def main() -> int:
    templates = sorted(GOLDEN_PATHS.glob("*/template.yaml"))
    if not templates:
        sys.exit("no golden paths found")

    for template in templates:
        validate_template(template)
        skeleton = template.parent / "skeleton"
        if skeleton.is_dir():
            validate_skeleton(skeleton)
        else:
            errors.append(f"{template.parent.name}: missing skeleton/ directory")

    if errors:
        for error in errors:
            print(f"ERROR {error}", file=sys.stderr)
        print(f"\n{len(errors)} problem(s) in {len(templates)} golden path(s)", file=sys.stderr)
        return 1

    print(f"OK: {len(templates)} golden path(s) validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
