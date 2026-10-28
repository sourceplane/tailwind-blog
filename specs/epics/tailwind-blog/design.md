# tailwind-blog — design

## The template

[timlrx/tailwind-nextjs-starter-blog](https://github.com/timlrx/tailwind-nextjs-starter-blog)
(v2.4, Next.js 15.5 App Router, Tailwind CSS 4, Contentlayer2, pliny) is a
blog: posts in `data/blog` as Markdown or MDX, compiled by Contentlayer with
remark/rehype (GFM, math with KaTeX, citations, Prism highlighting, GitHub
alerts, heading anchors), listed with pagination and tags, with author
pages, a projects page, an about page, light and dark themes, RSS feeds
(one for the blog, one per tag, written into `public/` by
`scripts/postbuild.mjs`), a sitemap, robots.txt, kbar search over a
`search.json` Contentlayer writes, comments (giscus by default), analytics
(Umami by default) and a newsletter route (`/api/newsletter`, Buttondown by
default). Its options are `data/siteMetadata.js`.

## How it maps to Cloudflare

| Vercel | Here | Why |
|---|---|---|
| Next.js hosting | One Worker built by `@opennextjs/cloudflare` (`output: 'standalone'`), its pre-rendered pages in the static-assets incremental cache | Every page is SSG; the cache needs no binding |
| `public/` (with the feeds and `search.json`) | Static assets | OpenNext ships `public/` |
| `/api/newsletter` | In the Worker, under `nodejs_compat` | pliny's handler calls the provider's API with its key |
| Image Optimization | Off: `images.unoptimized` | The Worker has no optimiser; the template has the mode built in |
| `headers()` security headers | Unchanged, sent by the Worker | OpenNext applies `next.config` headers |
| `siteUrl` (vercel.app) | `NEXT_PUBLIC_SITE_URL` per environment | Absolute links need the origin each environment is served on |

## The repository

portfolio-starter-kit's shape: `apps/web` (type
`cloudflare-workers-assets-turbo`, lane `isolated`) and `tests/web` (type
`turbo-package`, a vitest suite run on the `dev` rung). No infrastructure:
no database, no bucket. The site's name is one seam, `SITE_NAME` in
`data/siteMetadata.js`, which both `title` and `headerTitle` read; upstream's
`headerTitle: 'TailwindBlog'` spelled this baseline's Pascal form, which the
leftover sweep refuses. The source link is `siteRepo`, which the rename
points at the site's own repository; the post layout's "View on GitHub" link
follows it to `apps/web/data/`.

## The build

`next build` (webpack, with Contentlayer's plugin), `scripts/postbuild.mjs`
(the RSS feeds into `public/`), `opennextjs-cloudflare build --skipBuild`,
then `populateCache local` (the pre-rendered pages into the assets).
`repo-blueprint.yaml` is portfolio-starter-kit's: one landing (`01-product`)
places, brands and lands the whole tree, one convergence builds and deploys
stage and prod side by side, and `03-docs` records what went live. The smoke
checks the home page links the blog, a post renders, and `/feed.xml` is a
feed.

## Out of scope

- Algolia search, Plausible/PostHog/Google analytics and the other
  newsletter and comment providers: configuration in `siteMetadata.js`, as
  upstream; nothing to port.
- Static export (`EXPORT=1`), kept as upstream for anyone who wants it, not
  deployed.

## The alternative rejected

**Static export** (`output: 'export'`) served as plain assets, as astrowind
is. It would drop the newsletter route, which needs a server, and move the
blog off the OpenNext path every Next.js baseline here shares — with no
gain, since every page is pre-rendered either way.
