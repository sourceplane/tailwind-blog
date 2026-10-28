# tailwind-blog

Vercel's [Tailwind CSS Starter Blog](https://github.com/timlrx/tailwind-nextjs-starter-blog)
— a Next.js blog with Tailwind CSS: Markdown and MDX posts through
Contentlayer with tags, pagination, author pages and projects, math,
citations and syntax highlighting, RSS feeds, a sitemap, local search and
light and dark themes — running on **Cloudflare Workers + Static Assets**
through [`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), deployed by
[Orun](https://github.com/sourceplane/orun) to stage and prod on every merge.
Packaging it as an Orun baseline is the next milestone (TB2).

The template's code is the code. What the port adds is the Workers build
(OpenNext, after the template's own `next build` and RSS step), the monorepo
wrapper, a test package and the deploy contract; what it changes is the
site's origin (an environment variable, set per environment by the deploy),
the site's name (one seam, `SITE_NAME`), and image optimisation (off: the
Worker has none). See
[`specs/epics/tailwind-blog`](specs/epics/tailwind-blog/README.md) for the
design, the milestones and the as-built status.

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
