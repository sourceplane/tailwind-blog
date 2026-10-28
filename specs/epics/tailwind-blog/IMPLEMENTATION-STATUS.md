# tailwind-blog — implementation status

| Milestone | State | Landed |
|---|---|---|
| TB0 — the spec | ✅ | the repository's first commit |
| TB1 — the blog on Workers | ✅ | TB-2 |
| TB2 — a baseline | planned | TB-3 |

## Departures from the upstream template

Everything not listed here is the template as it is upstream at `b45bef6`.

| # | What | Why |
|---|---|---|
| 1 | The app lives in `apps/web` of a pnpm workspace; Yarn (`.yarn`, `.yarnrc.yml`, `yarn.lock`), Husky, lint-staged, the devcontainer and `faq/` are not carried | The workspace has one lockfile, `pnpm-lock.yaml`; the FAQ is the template's own documentation |
| 2 | `next.config.js`: `output: 'standalone'` (export still behind `EXPORT`), `outputFileTracingRoot` and `turbopack.root` at the workspace root, `images.unoptimized` always | OpenNext builds from the standalone output; the Worker has no image optimiser |
| 3 | `open-next.config.ts` (static-assets incremental cache) and `wrangler.jsonc` | The Workers build |
| 4 | `build` adds `opennextjs-cloudflare build --skipBuild` and `populateCache local` after the template's own steps; `typecheck` and `lint` run `contentlayer2 build` first; `lint` is `eslint` over the template's directories (no `--fix`) | The workspace's `typecheck` / `lint` / `test` / `build` contract |
| 5 | `data/siteMetadata.js`: `SITE_NAME` is `title` and `headerTitle`; `siteUrl` is `NEXT_PUBLIC_SITE_URL`; `siteRepo` is the site's repository | One rename seam; the origin per environment; the source link a site's own |
| 6 | `layouts/PostLayout.tsx`: "View on GitHub" points under `apps/web/data/` | The posts' path in the workspace |
| 7 | Three layouts reformatted by the template's own Prettier config (Tailwind class order) | Upstream's lint ran with `--fix`; this one checks |
| 8 | `tsconfig.json` excludes `.open-next`, `.wrangler` and `eslint.config.mjs` | Build output is not source; the ESLint config's inferred type breaks `composite` declarations |
| 9 | `.env.example` says which variables are build-time and which are Worker secrets | Workers read runtime secrets from the Worker, not the build |
| 10 | `tests/web` (vitest) | The template ships none |
