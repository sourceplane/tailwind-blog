# apps/web — the blog

[timlrx/tailwind-nextjs-starter-blog](https://github.com/timlrx/tailwind-nextjs-starter-blog)
(MIT, `LICENSE`): Next.js, Tailwind CSS and Contentlayer, built by
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare) into one
Cloudflare Worker with Static Assets.

- Posts are `data/blog/*.md|mdx` (Contentlayer, `contentlayer.config.ts`);
  authors `data/authors/`, projects `data/projectsData.ts`
- `/`, `/blog` (paginated), `/blog/<slug>`, `/tags`, `/tags/<tag>`,
  `/projects`, `/about`, `/sitemap.xml`, `/robots.txt`
- `/feed.xml` and `/tags/<tag>/feed.xml` (written into `public/` by
  `scripts/postbuild.mjs`), `/search.json` (Contentlayer, for kbar search)
- `/api/newsletter` — the newsletter form, in the Worker

The site's name, source link and every theme option (analytics, comments,
newsletter, search) are `data/siteMetadata.js`.

```bash
pnpm dev        # next dev on http://localhost:3000
pnpm typecheck  # contentlayer2 build, then tsc
pnpm build      # next build → RSS → opennextjs-cloudflare build → .open-next/
pnpm preview    # wrangler dev over the built Worker
```

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
