# tailwind-blog — operating contract (for humans and agents)

This is the standing guide to how this site is deployed and operated.
Instance facts (live URLs, workspace, the secrets it uses) live in
[deployment.md](deployment.md), rendered from probed reality by the
bootstrap's `03-docs` phase; this file is the contract that stays true
between deployments. It is written to give an agent with repository read
access enough context to reason about and operate the site without any
other source.

## What this system is

A Tailwind CSS blog on Cloudflare alone, expressed as an Orun
component-native desired-state repo.

- **`apps/web`** — the site: Next.js built by `@opennextjs/cloudflare` into
  one Worker plus Static Assets. Contentlayer compiles the posts in
  `data/blog` at build time; every page is pre-rendered and served from the
  assets cache, and the RSS feeds and the search index are files the build
  writes into the assets. `/api/newsletter` runs in the Worker. There is no
  database; the only runtime secret is an optional newsletter provider key.
- **`tests/web`** — the site-identity, origin, post front-matter and header
  link tests (vitest), verified on the `dev` rung.
- **`tooling/*`** — shared TypeScript and ESLint configuration, and the
  deploy-time wrangler renderer for workers that take wiring.

Environments: **`stage`** and **`prod`** are deployed; **`dev` is
verify-only by design** — lanes build and test, nothing deploys.

## Identity and tenancy

Every remote operation runs against ONE Orun workspace, declared in
`intent.yaml` under `execution.state.workspace` — committed, enforced, and
what CI uses. Do not remove it; headless credentials depend on it. If it
reads `ws_SET_ME`, the bootstrap had no workspace to write: set the real one
before anything else.

## How deployment works

1. Merge (or push) to `main`.
2. CI (`.github/workflows/ci.yml`) runs `orun plan --changed` — only
   components whose files changed are planned — then runs each planned lane
   with `orun run --remote-state`, authenticated by GitHub OIDC (the
   exchange resolves this repository's linked workspace server-side).
3. `apps/web` builds once per environment, with `NEXT_PUBLIC_SITE_URL` set to
   that environment's `SITE_URL` (intent.yaml) or its workers.dev URL, then
   `wrangler deploy` ships `tailwind-blog-web-<env>` and a smoke test
   fetches `/`, a post and `/feed.xml` from it.
4. `prod` deploys after `stage` has converged on the same commit
   (`environments.prod.promotion` in intent.yaml).
5. **The convergence run is the deployment.** A green run means every
   planned lane applied. Failed lanes are retried with
   `gh run rerun --failed`, which resumes the same execution.

Caveats that matter:

- A push that touches no component files plans zero lanes — that run is
  green and deployed nothing. Never treat "latest run green" as "site
  converged"; probe the URLs instead.
- A change to `intent.yaml`'s `environments` (a new `SITE_URL`, say) maps to
  no component and redeploys nothing on its own. Land it with a change under
  `apps/web`.

## Secrets model

- **Brokered provider secrets**: `CLOUDFLARE_API_TOKEN` (Workers deploy
  scope) and `CLOUDFLARE_ACCOUNT_ID` — pointers minted per run from the
  workspace's Cloudflare connection. No long-lived values at rest; nothing
  to rotate by hand.
- Inspect by NAME only: `orun secrets list --org <ws> --project` and
  `--env stage|prod`. No tooling in this repository prints a secret value,
  and no document in `ai/context/` may contain one.
- The newsletter route reads its provider's key (`BUTTONDOWN_API_KEY` by
  default) at request time: a Worker secret, set with `wrangler secret put`
  on each environment's Worker. Without it the form answers an error and
  nothing else changes. Comment and analytics ids (`NEXT_PUBLIC_GISCUS_*`,
  `NEXT_UMAMI_ID`) are public and read at build time.

## Verifying the system

```bash
# the site on each environment (also recorded, probed, in deployment.md)
curl -s -o /dev/null -w '%{http_code}\n' https://tailwind-blog-web-stage.your-workers-subdomain.workers.dev/
curl -s https://tailwind-blog-web-prod.your-workers-subdomain.workers.dev/feed.xml | head -5

# workspace readiness (integrations + repository link)
orun integrations list --org <ws> --json && orun cloud check --org <ws>
```

## Common operations

| task | how |
|---|---|
| publish a post | add `apps/web/data/blog/<slug>.mdx` (front matter `title`, `date`, `tags`, `summary`), run `pnpm build` once so `apps/web/app/tag-data.json` is regenerated, commit both, merge |
| deploy a change | merge to `main`; watch the run; failed lanes → `gh run rerun --failed` |
| deploy by hand | Orunbase's Deploy button, or `gh workflow run ci.yml --ref main -f environment=<env> [-f component=<a,b>]` — the named components (blank: every one) run in that environment as a merge runs them; started off `main` it is refused |
| redeploy without a change | edit the last line of `apps/web/component.yaml` (`# orun: redeploy <reason> <stamp>`) and merge — it is a deploy trigger, nothing reads it |
| serve a custom domain | attach it to the Worker in Cloudflare, set `SITE_URL` for the environment in `intent.yaml`, and replace the placeholder `tailwind-blog.example.com` in `intent.yaml`'s `BASE_DOMAIN` (dev, stage and prod) with it (README, "Custom domain") |
| turn on the newsletter | `pnpm exec wrangler secret put BUTTONDOWN_API_KEY --name tailwind-blog-web-<env>` from `apps/web` (or another provider's key, with `newsletter.provider` in `apps/web/data/siteMetadata.js`) |
| add a runtime secret | `orun secrets set <KEY> --org <ws> --env <env>` |
| headless credentials | `ORUN_TOKEN` (workspace-scoped) + `GITHUB_TOKEN` |

The deployment record is the bootstrap's `03-docs` phase. Re-running it (the
Orun console's Retry on that phase, or `orun new … --phase 03-docs`)
re-probes the URLs and re-renders [deployment.md](deployment.md); it is
idempotent.

## Evolution

Structural changes (a second Worker, an API, a data store) follow the same
contract that deployed the site: add a component under `apps/`, `infra/` or
`packages/` with a `component.yaml`, land it as a pull request, and the
convergence run applies it.
