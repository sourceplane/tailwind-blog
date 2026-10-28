# tailwind-blog — Vercel's Tailwind CSS Starter Blog on Cloudflare Workers

**The template's own build — `next build`, then its RSS step — then OpenNext:
one Cloudflare Worker with every page pre-rendered into its Static Assets,
deployed by Orun to stage and prod on every merge — and the baseline that
makes a copy of it somebody else's blog in one landing.**

| | |
|---|---|
| Status | In progress — TB0 on main |
| Upstream | [timlrx/tailwind-nextjs-starter-blog](https://github.com/timlrx/tailwind-nextjs-starter-blog) (MIT), at `b45bef6` (2026-02-08) |
| Reference | [portfolio-starter-kit](https://github.com/sourceplane/portfolio-starter-kit) — the same scaffolding, tests and bootstrap; [blog-starter](https://github.com/sourceplane/blog-starter) — the same kind of site |
| Key | `TB` |

## Read in this order

1. [design.md](design.md) — the template, how each Vercel piece maps to
   Cloudflare, the repository and the build, and the alternative rejected.
2. [implementation-plan.md](implementation-plan.md) — the milestones and
   what each one lands.
3. [risks-and-open-questions.md](risks-and-open-questions.md) — what is not
   proven, and what was accepted.
4. [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md) — what shipped, and
   every departure from the upstream template.

## Milestones

| Milestone | What it lands | Task |
|---|---|---|
| TB0 — the spec | the repository, its intent, CI, tooling and spec index; this doc set | TB-1 |
| TB1 — the blog on Workers | the template in `apps/web`, built by OpenNext into one Worker; `tests/web` | TB-2 |
| TB2 — a baseline | the console card, the build document, the context pack and the baseline's tests | TB-3 |
