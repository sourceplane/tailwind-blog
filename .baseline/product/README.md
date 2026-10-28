# tailwind-blog

A blog built with [Next.js](https://nextjs.org/) and
[Tailwind CSS](https://tailwindcss.com/) — Markdown and MDX posts through
[Contentlayer](https://github.com/timlrx/contentlayer2) with tags,
pagination, author pages and projects, math, citations and syntax
highlighting, RSS feeds, a sitemap, local search and light and dark themes —
on **Cloudflare Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare).

Working on it with a coding agent? [AGENTS.md](AGENTS.md) says what to read
first, how a change lands and what not to touch.

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the site uses into
[ai/context/deployment.md](ai/context/deployment.md); how the site deploys
and how to operate it is in
[ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The site's name, source link and theme options | `apps/web/data/siteMetadata.js` |
| Posts (Markdown/MDX with front matter), authors, projects | `apps/web/data/blog`, `apps/web/data/authors`, `apps/web/data/projectsData.ts` |
| Pages: home, `/blog`, `/blog/[...slug]`, `/tags`, `/projects`, `/about` | `apps/web/app` |
| Layouts and components | `apps/web/layouts`, `apps/web/components` |
| Content model (Contentlayer), the RSS feeds | `apps/web/contentlayer.config.ts`, `apps/web/scripts/rss.mjs` |
| The newsletter route | `apps/web/app/api/newsletter/route.ts` |
| Workers build and deploy contract | `apps/web/next.config.js`, `open-next.config.ts`, `wrangler.jsonc`, `component.yaml` |
| Tests | `tests/web` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck        # Contentlayer, then tsc
pnpm lint
pnpm test
pnpm build            # next build, the RSS feeds, then opennextjs-cloudflare build → apps/web/.open-next
```

```bash
pnpm --filter @app/web dev        # http://localhost:3000
pnpm --filter @app/web preview    # wrangler dev over the built Worker
```

Write a post by dropping a `.md` or `.mdx` file with front matter (`title`,
`date`, `tags`, `summary`) into `apps/web/data/blog/`. Make the site yours in
`apps/web/data/siteMetadata.js` (its name, author, source link, social
links, and the analytics, comments, newsletter and search providers) and
`apps/web/data/authors/default.mdx`.

Optional variables are listed in `apps/web/.env.example`:

| Variable | What it does |
|---|---|
| `NEXT_PUBLIC_SITE_URL` | The site's public origin for sitemap, RSS, canonical and Open Graph links. The deploy sets it per environment (see below). Defaults to `http://localhost:3000`. |
| `NEXT_PUBLIC_GISCUS_*` | Comments through giscus (`comments.provider` in `siteMetadata.js`). Public, read at build time. |
| `NEXT_UMAMI_ID` | Umami analytics. |
| `BUTTONDOWN_API_KEY` (or another provider's) | The newsletter form (`newsletter.provider`). Read at request time: a Worker secret, `pnpm exec wrangler secret put BUTTONDOWN_API_KEY --name tailwind-blog-web-<env>` from `apps/web`. |

## How it deploys

Merges to `main` converge through [Orun](https://github.com/sourceplane/orun):
`.github/workflows/ci.yml` plans the changed components and runs each lane
against the workspace in `intent.yaml`. The site deploys to `stage`, then to
`prod` once stage has converged on the same commit; `dev` only verifies. The
Worker is `tailwind-blog-web-<env>` on your account's workers.dev
subdomain, and every deploy is smoke-tested over HTTP. A pull request runs
the same pipeline's verify lanes: the site built and dry-deployed for each
environment, with nothing deployed. They do not lint or run the tests, so
run `pnpm typecheck`, `pnpm lint` and `pnpm test` before you push. (A push
to `main` builds, deploys and smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The
Cloudflare token and account id are brokered per run from the workspace's
Cloudflare connection; nothing provider-shaped is stored in the repository
or in GitHub.

**Deploy by hand.** Orunbase's **Deploy** button on a component, or **Run
workflow** on the CI workflow in GitHub's Actions tab (on `main`), runs
`ci.yml` for the environment and components you pick, and each one deploys
exactly as a merge would deploy it. Leave the component blank to redeploy
every component in that environment, with nothing changed: after rotating a
secret, say. A component with nothing to run in that environment (a test
suite in `prod`) is left out with a notice.

## Custom domain

The site answers on workers.dev from its first deploy. To serve it on your
own domain:

1. Add the domain to the Cloudflare account the site deploys into, and attach
   it to the Worker (dashboard → Workers & Pages →
   `tailwind-blog-web-prod` → Settings → Domains & Routes → Add →
   Custom domain). Do the same for stage with a subdomain if you want one.
2. Set the environment's public origin in `intent.yaml`, so sitemap, RSS,
   canonical and Open Graph links use it (until then they use the
   workers.dev URL):

   ```yaml
   environments:
     prod:
       env:
         SITE_URL: https://tailwind-blog.example.com
   ```

   The site was born with the reserved placeholder
   `tailwind-blog.example.com` where its domain goes: that example,
   and `BASE_DOMAIN` under each environment (dev, stage and prod) in
   `intent.yaml`. Replace it with your domain in the same change.

3. Merge. The next deploy of `apps/web` builds with the new origin. (A change
   to `intent.yaml` alone deploys nothing — touch `apps/web` in the same pull
   request, or let the next change to the site carry it.)

## Credits

The blog is [timlrx/tailwind-nextjs-starter-blog](https://github.com/timlrx/tailwind-nextjs-starter-blog)
(MIT, `apps/web/LICENSE`); the footer's "Tailwind Nextjs Theme" link credits
it.
