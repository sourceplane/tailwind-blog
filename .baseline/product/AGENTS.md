# tailwind-blog — for coding agents

Start here before you change this site. This page is short on purpose: the
pages it points at hold the detail, and they are kept true.

## What this is

A blog: Next.js with Tailwind CSS, Markdown/MDX posts through Contentlayer
(tags, pagination, authors, projects, math, citations, syntax highlighting),
RSS feeds, a sitemap and local search, built by `@opennextjs/cloudflare`
into one Cloudflare Worker with Static Assets. Orun deploys it to `stage` and
`prod` on every merge to `main`; `dev` only verifies. One deployable
component (`apps/web`) and its tests (`tests/web`); no database and no
runtime secret (a newsletter provider's key is optional).

## Read first, in this order

1. [README.md](README.md) — what is where, how to run it, the live URLs.
2. [ai/context/operations.md](ai/context/operations.md) — the operating
   contract: how a merge deploys, the secrets model, common operations.
3. [ai/context/deployment.md](ai/context/deployment.md) — what is live, as
   last probed.
4. [apps/web/docs/overview.md](apps/web/docs/overview.md) — the component,
   with `architecture.md` and `runbook.md` beside it.
5. [apps/web/data/siteMetadata.js](apps/web/data/siteMetadata.js) — the
   site's name, its source link, and every option the theme reads
   (analytics, comments, newsletter, search).

## Working on it

```bash
pnpm install && pnpm typecheck && pnpm lint && pnpm test && pnpm build
pnpm --filter @app/web dev        # http://localhost:3000
```

A post is `apps/web/data/blog/<slug>.mdx` (or `.md`) with front matter
`title`, `date`, `tags`, `summary` (and optionally `authors`, `draft`,
`layout`, `images`). Authors are `apps/web/data/authors/`, projects
`apps/web/data/projectsData.ts`, the header's links
`apps/web/data/headerNavLinks.ts`. Contentlayer regenerates
`apps/web/app/tag-data.json` on every build: commit it with the posts that
change it.

## How a change lands

- The repository is desired state. `intent.yaml` declares the environments
  and the workspace; `apps/web/component.yaml` declares how the site is
  built, deployed and smoke-tested.
- `orun plan --changed` shows which components and environments a change
  touches. CI runs the same plan on every pull request.
- One task, one pull request to `main`. On the pull request `ci.yml`'s
  verify lanes run (the site built and dry-deployed per environment); they
  do not lint or run the tests, so run `pnpm typecheck && pnpm lint && pnpm
  test` before you push. The merge's `ci.yml` run deploys stage and prod and
  smoke-tests each. That run is the deployment: retry a red lane with
  `gh run rerun --failed`.
- With Orun's work plane: `orun task create --brief "…"` issues a task key,
  `orun pr open --task <KEY>` opens its pull request on `orun/<KEY>-<slug>`,
  and `orun pr land` merges it once its checks pass. Leave the `BASE` prefix
  to the bootstrap: CI checks `orun/BASE-…` branches with `plan` alone.
- A change to `intent.yaml` alone (a `SITE_URL`, say) deploys nothing;
  carry it with a change under `apps/web`.

## Do not touch

- `execution.state.workspace` in `intent.yaml`: every remote operation, and
  CI's OIDC exchange, claims that workspace.
- `ai/context/deployment.md`, and the README between `<!-- 03-docs:begin -->`
  and `<!-- 03-docs:end -->`: rendered from probed URLs, never by hand.
- `.rebrand/values.json`: the identity the site was created with, which the
  deployment record is rendered from.
- Secrets. `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` are brokered
  per run from the workspace's Cloudflare connection; never put a value in
  the repository or in GitHub. List them by name (operations.md).
- `ci.yml` stays the only workflow that runs on a push to `main`.
- `pnpm-lock.yaml` changes through `pnpm install`, never by hand: CI
  installs with `--frozen-lockfile`.
