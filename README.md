# tailwind-blog

Vercel's [Tailwind CSS Starter Blog](https://github.com/timlrx/tailwind-nextjs-starter-blog)
— a Next.js blog with Tailwind CSS: Markdown and MDX posts through
Contentlayer with tags, pagination, author pages and projects, math,
citations and syntax highlighting, RSS feeds, a sitemap, local search and
light and dark themes — running on **Cloudflare Workers + Static Assets**
through [`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), and
packaged as an **Orun baseline**: one command takes a new site from nothing
to live on stage and prod, in its own repository, under its own name.

The template's code is the code. What the port adds is the Workers build
(OpenNext, after the template's own `next build` and RSS step), the monorepo
wrapper, a test package and the deploy contract; what it changes is the
site's origin (an environment variable, set per environment by the deploy),
the site's name (one seam, `SITE_NAME`), and image optimisation (off: the
Worker has none). What the baseline adds is everything needed to make a copy
of it somebody else's — built the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) is. See
[`specs/epics/tailwind-blog`](specs/epics/tailwind-blog/README.md) for the
design, the milestones and the as-built status.

## Instantiating a site

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/tailwind-blog
cd tailwind-blog
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-notes --run-hooks --resume \
  --set reponame=acme-notes --set productname="Acme Notes" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`tailwind-blog` → Build). Two phases — `01-product` (the repository
created, then the whole site in one pull request, deployed to stage and prod
and smoke-tested) and `03-docs` (the live deployment recorded) — each landing
one pull request in the new repository.
**[BOOTSTRAP.md](BOOTSTRAP.md)** is the operator guide;
[docs/phases/](docs/phases/README.md) has a page per phase.

The new repository receives the **site only** — the app, its tests, its CI,
its tooling, a README and an `AGENTS.md` of its own and its operating
contract — renamed throughout to the site's name, repository and Cloudflare
Worker. None of this repository's machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The site's README, agent page and context pack | `.baseline/product/README.md`, `.baseline/product/AGENTS.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

## What is here (the site)

| Surface | Where |
|---|---|
| The site's name, source link and theme options | `apps/web/data/siteMetadata.js` |
| Posts, authors, projects | `apps/web/data/blog`, `apps/web/data/authors`, `apps/web/data/projectsData.ts` |
| Pages, layouts, components | `apps/web/app`, `apps/web/layouts`, `apps/web/components` |
| Content model, RSS feeds | `apps/web/contentlayer.config.ts`, `apps/web/scripts/rss.mjs` |
| Workers build and deploy contract | `apps/web/next.config.js`, `open-next.config.ts`, `wrangler.jsonc`, `component.yaml` |
| Tests | `tests/web` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck        # Contentlayer, then tsc
pnpm lint
pnpm test
pnpm build            # next build, the RSS feeds, opennextjs-cloudflare build → apps/web/.open-next
```

```bash
pnpm --filter @app/web dev        # http://localhost:3000
pnpm --filter @app/web preview    # wrangler dev over the built Worker
```

## How it maps to Vercel

| Vercel | Here |
|---|---|
| Next.js hosting (SSG + a route handler) | One Cloudflare Worker (`.open-next/worker.js`) + Static Assets; every page is pre-rendered and served from the static-assets cache, `/api/newsletter` runs in the Worker |
| `next build` then `scripts/postbuild.mjs` (RSS into `public/`) | Unchanged, then `opennextjs-cloudflare build`, which ships `public/` — the feeds and Contentlayer's `search.json` — as static assets |
| Image Optimization (`next/image`) | Off (`images.unoptimized`, the template's own `UNOPTIMIZED` mode): the Worker serves images as they are |
| `next.config.js` `headers()` (CSP and the rest) | Unchanged: the Worker sends them with every page |
| `siteUrl: https://tailwind-nextjs-starter-blog.vercel.app` | `NEXT_PUBLIC_SITE_URL`, set per environment by the deploy: its `SITE_URL`, else its workers.dev URL |
| Environment variables (giscus, Umami, a newsletter key) | Build-time `NEXT_PUBLIC_*` as before; the newsletter key is a Worker secret (`apps/web/.env.example`) |
| Deploy on push | Orun deploys `<repo>-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`) |
| "Deploy with Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a site |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a site carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the site built and dry-deployed per environment; the tests' `quick-check` lane installs and checks the package, it does not run them), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does. A manual run (Orunbase's Deploy button, or Run workflow on `main`) plans the environment and components it names under the push-to-main trigger, so they deploy as a merge deploys them | yes |
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the site built, dry-deployed and served | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |
