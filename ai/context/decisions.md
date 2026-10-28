# tailwind-blog — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | Next.js on Workers + Static Assets through `@opennextjs/cloudflare`, with the static-assets incremental cache | Every page is pre-rendered; the cache serves them from the assets with no binding | `specs/epics/tailwind-blog/design.md` |
| 2 | The template's own Next.js (15.5.12) and Contentlayer2 (0.5.8), not Next 16 | Contentlayer's webpack plugin and pliny are pinned against it; OpenNext 1.20 builds it | risk TB-D |
| 3 | The build is the template's — `next build`, then `scripts/postbuild.mjs` (RSS into `public/`) — then OpenNext | OpenNext ships `public/` as assets, so the feeds and Contentlayer's search index are static files | `apps/web/package.json` |
| 4 | `typecheck` and `lint` run `contentlayer2 build` first | `contentlayer/generated` is what the pages import; the landing's checks type-check before they build | `apps/web/package.json` |
| 5 | Images unoptimised (`images.unoptimized`, the template's own `UNOPTIMIZED` mode) | The Worker has no image optimiser | risk TB-C |
| 6 | The site's name is one seam, `SITE_NAME` in `apps/web/data/siteMetadata.js`, for `title` and `headerTitle` both | The rename rewrites one literal, and `headerTitle` (`TailwindBlog`) spelled this baseline's Pascal form | IMPLEMENTATION-STATUS (departures) |
| 7 | `siteUrl` is `NEXT_PUBLIC_SITE_URL`, set per environment by the deploy (its `SITE_URL`, else its workers.dev URL) | The sitemap, the feeds and canonical links are absolute; each environment builds anyway (portfolio-starter-kit's shape) | `apps/web/component.yaml` |
| 8 | `siteRepo` is the site's own repository; the footer's "Tailwind Nextjs Theme" link stays the template's | The source link is a site's; the credit is the template's | IMPLEMENTATION-STATUS (departures) |
| 9 | The newsletter key is a Worker secret set by hand; nothing provider-shaped is brokered | The route reads it at request time; it is optional, and the template's providers are many | operations.md |
| 10 | No custom-domain phase: a domain is the owner's step, and `SITE_URL` points the build at it | The brokered `workers-deploy` token has no zone scope | README, "Custom domain" |
| 11 | One landing (`01-product`) then the record (`03-docs`), each checked in the build box | A landing has a fixed cost; the convergence on main builds, deploys and smoke-tests the site for real | `docs/phases/README.md` |
| 12 | `ci.yml` plans nothing while `intent.yaml` names `ws_CHANGE_ME`; no Checks workflow | A bootstrap cannot set a repository variable; a push to main must start `ci.yml` alone | `.github/workflows/ci.yml` |
| 13 | stack-tectonic 0.19.0, not 0.20.0 | 0.20.0's lane-shared install links `node_modules` out of the job's tree | risk TB-F |
| 14 | Component docs are generated from the manifests and checked in CI; orun is pinned only where it runs | A hand-written copy drifts silently | `tooling/catalog/gen-component-docs.py` |
| 15 | `subdomain` is read from the Cloudflare connection, never asked; the console asks for no domain | Both belong to the account or the owner, not to the build | `blueprint.yaml` |
