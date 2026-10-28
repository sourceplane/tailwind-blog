# tailwind-blog — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a site built from it; the
pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md), with the site's `AGENTS.md`.

## What it is

Vercel's Tailwind CSS Starter Blog (timlrx/tailwind-nextjs-starter-blog) — a
Next.js and Tailwind CSS blog with Markdown/MDX posts through Contentlayer,
tags, pagination, authors, projects, RSS feeds, a sitemap and local search —
built by OpenNext into one Cloudflare Worker with Static Assets, packaged as
an Orun baseline: `orun new --blueprint repo-blueprint.yaml` builds a new
blog in its own repository and takes it to live on stage and prod in one
landing (`01-product`), then records what went live (`03-docs`).

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` — TB0 to TB2: the repository, the blog on Workers, and the baseline (blueprint, phases, tests) |
| Proven live | Not yet: proven offline in Baseline CI only (risk TB-A) |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/tailwind-blog/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/tailwind-blog/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/tailwind-blog/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What the components are | `apps/web/docs/`, `tests/web/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |

## Next

1. Bootstrap one blog from `baseline-v1` from the console and record its
   timings against the 5-minute estimate (closes TB-A); then the registry
   row goes public with the measured minutes.
