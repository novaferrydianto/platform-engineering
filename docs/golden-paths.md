# Authoring a Golden Path

A golden path is a Backstage Software Template: a wizard (`template.yaml`)
that renders a reusable starter (`skeleton/`) into a new, registered repo.

## Structure

```
golden-paths/<path-name>/
├── template.yaml     # apiVersion: scaffolder.backstage.io/v1beta3, kind: Template
└── skeleton/          # everything that gets rendered into the new repo
    ├── catalog-info.yaml
    ├── Dockerfile
    ├── helm/
    ├── .github/workflows/ci.yml   # calls the shared reusable workflows
    └── ... app source ...
```

## Checklist for a new path

1. **Copy the closest existing path** (`golden-paths/go-service` for a new
   backend service — it's the recommended default; `nodejs-service` or
   `python-fastapi-service` when the team specifically needs that runtime;
   `golden-paths/static-site` for a frontend) as a starting point rather than
   writing `template.yaml` from scratch.
2. **`template.yaml` parameters** — always collect at minimum: `name`,
   `description`, `owner` (catalog entity ref), `system`. Add path-specific
   parameters (e.g. `cloud`, `environment`) only if the skeleton actually
   branches on them.
3. **`skeleton/catalog-info.yaml`** — every generated repo must self-register
   in the catalog (`kind: Component`, correct `spec.owner`/`spec.system`,
   `spec.type`, links to TechDocs).
4. **`skeleton/.github/workflows/ci.yml`** — must be a thin caller into
   `.github/workflows/reusable-*.yml` in this repo (referenced by
   `owner/platform-engineering/.github/workflows/reusable-build.yml@main`).
   Do not inline build/test/scan logic into the skeleton — that defeats the
   point of centralizing CI/CD templates.
5. **`skeleton/Dockerfile` and `skeleton/helm/`** — must run as non-root,
   define resource requests/limits, and pass
   `reusable-security-scan.yml`'s container scan step out of the box.
6. **Register the template** — add its `template.yaml` location to
   `idp-portal/app-config.yaml` under `catalog.locations` so it appears in
   the portal's Create page.
7. **Test it standalone** before wiring into the portal: copy `skeleton/`,
   fill in placeholders by hand, confirm it builds and its CI workflow is
   valid YAML.

## When to promote shared code

If a third golden path needs the same boilerplate a second one already has
(e.g. identical Helm chart structure, identical OpenTelemetry bootstrap),
extract it into a shared fetch source instead of copying a third time — see
the "rule of three" note in [`architecture.md`](architecture.md).
