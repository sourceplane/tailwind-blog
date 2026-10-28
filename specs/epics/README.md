# Epics

Orun-style work programs. Each epic is a folder carrying `epic.yaml` (the
declaration the platform reads: slug, key prefix, milestones with exit
criteria and task keys) beside its doc set. The pull request that adds the
folder is the adoption; the merge creates the epic in the workspace.

| Epic | Cluster | Status | What it is |
|------|---------|--------|------------|
| [`tailwind-blog/`](./tailwind-blog/) | **TB** | In progress (TB1: the site on Workers) | Vercel's Tailwind CSS Starter Blog — Next.js, Tailwind CSS and Contentlayer — on Cloudflare Workers + Static Assets through OpenNext, and an Orun baseline that instantiates it (TB2) |

As-built ≠ intent: what shipped lives in each epic's `IMPLEMENTATION-STATUS.md`.
