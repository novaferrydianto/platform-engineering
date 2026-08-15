# ${{ values.name }}

${{ values.description }}

Scaffolded from the **Static Site** golden path. Owner: `${{ values.owner }}`.
Hosted on `${{ values.cloud }}` · initial environment: `${{ values.environment }}`.
{% if values.customDomain %}Custom domain: `${{ values.customDomain }}`.{% endif %}

## Local development

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # emits dist/
```

## CI/CD

`.github/workflows/ci.yml` builds and uploads `dist/`, then
`reusable-static-deploy.yml` syncs it to the cloud's object storage and
invalidates the CDN cache. Auth to the cloud is OIDC — there are no long-lived
credentials in this repo.

## Caching

Hashed assets under `assets/` are immutable and long-cached; `index.html` is
short-cached so a deploy takes effect immediately. The deploy workflow sets
these headers — don't override them per-file here.
