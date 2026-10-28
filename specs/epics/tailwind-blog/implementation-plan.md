# tailwind-blog — implementation plan

Three milestones, each one reviewed pull request (TB0 is the repository's
first commit), each green before it merges.

## TB0 — the spec (TB-1)

The repository is born: `intent.yaml` with the placeholder workspace
`ws_CHANGE_ME`, `ci.yml` (byte for byte turso-starter's, which plans nothing
until the workspace is set), the shared TypeScript and ESLint configuration,
the spec index, this doc set and the task contracts.

## TB1 — the blog on Workers (TB-2)

- The template's `app/`, `components/`, `layouts/`, `data/`, `css/`,
  `public/`, `scripts/` and configuration in `apps/web`; its dependencies,
  with `@opennextjs/cloudflare` and `wrangler`.
- `next.config.js`: `output: 'standalone'`, the workspace root for the
  trace, images unoptimised. `open-next.config.ts` with the static-assets
  incremental cache; `wrangler.jsonc`.
- `SITE_NAME` in `data/siteMetadata.js`, `siteUrl` from
  `NEXT_PUBLIC_SITE_URL`, `siteRepo` the site's own.
- `component.yaml`: the deploy contract (the origin per environment) and its
  smoke. `tests/web`: the identity, the origin, the posts' front matter, the
  header's links.
- The README's "How it maps to Vercel".

## TB2 — a baseline (TB-3)

portfolio-starter-kit's machinery, renamed: `blueprint.yaml`,
`repo-blueprint.yaml` (Contentlayer's output and the build's `public/`
files ignored), `.baseline/` (identity, the product's README and
`AGENTS.md`, task contracts), `tooling/rebrand`, `tooling/bootstrap`,
`hooks/render-deployment-docs.sh` (probing `/` and `/feed.xml`),
`docs/phases/`, the context pack, `testing/` (the leak and placement gates
on this tree's files; the e2e tier reading every route the blog promises)
and `baseline.yml` / `tag.yml`.
