#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the finished site, the landing's own checks — install with the
#      lockfile the site ships, render fixtures, typecheck, lint, test,
#      build. The bootstrap's own landings are checked in the box with
#      `orun validate` and `orun plan` alone (`checks: local`; their PR's CI
#      on an `orun/BASE-…` branch is `plan` alone, and the convergence on
#      main builds, deploys and smoke-tests the site), so THIS is where a
#      site those steps refuse is caught: before the tag, not after a build
#      has merged it. Every later pull request of the site runs ci.yml's
#      verify lanes;
#   2. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `build-app` — the component's
#      buildCommand, origin and all, the same step the deploy profile runs —
#      `verify-build-output` and `deploy-dry-run` (`wrangler deploy --dry-run
#      --name <reponame>-web-stage`). They run IN THE TREE THE RUNNER STAGES
#      for the job (testing/lib/stage-job.py), with the dependency layout the
#      pinned composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. Run in a plain
#      checkout, this tier was green while the first live bootstrap's lanes
#      died in the lane layout (Turbopack: "Symlink … points out of the
#      filesystem root");
#   3. serve the built Worker with `wrangler dev` and run the component's OWN
#      `smokeCommand` against it, verbatim — the check the real deploy ends
#      with — and then read every route the site promises: the heading and
#      title carry the site's name, the nav links the site's repository, the
#      feed and the sitemap are absolute on the stage origin, the Open Graph
#      route renders a PNG, an unknown post is a 404.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: two installs and builds
# (the landing's checks over the site, and the stage lane's own in its staged
# tree).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
sub="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['subdomain'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false NEXT_TELEMETRY_DISABLED=1 TURBO_TELEMETRY_DISABLED=1

# The landing's own checks, step for step, run here at once on the whole
# tree. A pull request in the site builds and dry-deploys it through ci.yml's
# lanes; the lint and the tests run here, and by hand before a push.
LANDING_CHECKS=(
  "pnpm install --frozen-lockfile"
  "pnpm run wire:fixture"
  "pnpm typecheck"
  "pnpm lint"
  "pnpm test"
  "pnpm build"
)
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  for cmd in "${LANDING_CHECKS[@]}"; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   2 phases placed and landed"

# ── 1. the finished site ───────────────────────────────────────────────────
echo "── the finished site: install, the fixture render, typecheck, lint, test, build"
checks "$tree" "$scratch/checks-site.log"

# ── 2. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: build-app, verify-build-output, deploy-dry-run"
# The 01-product landing over the repository's empty first commit: every file
# of the site changed, as on its pull request.
s00="$(git -C "$tree" rev-parse HEAD~2)"; s01="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s00" --head "$s01" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "web" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/web")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 1
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/web/.open-next" "$tree/apps/web/.wrangler"
work="$tree/.orun/runs/e2e/web.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done

# ── 3. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/web" && exec setsid pnpm exec wrangler dev --config wrangler.jsonc --ip 127.0.0.1 --port "$port" \
   --name "$repo-web-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/web/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the site promises"
python3 - "$url" "$values" "https://$repo-web-stage.$sub.workers.dev" <<'PY'
import html, json, re, sys, urllib.error, urllib.request
import xml.etree.ElementTree as ET
base, values, origin = sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3]
name, repo, org = values["productname"], values["reponame"], values["githuborg"]
problems = []
def bad(m): problems.append(m)
def get(path, method="GET", data=None):
    req = urllib.request.Request(base + path, method=method, data=data,
                                 headers={"content-type": "application/json"} if data else {})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()
def text(fragment):
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()

# / — the latest posts, under the site's name in the header and the title.
status, headers, body = get("/")
page = body.decode()
if status != 200:
    bad(f"/ answered {status}")
title = re.search(r"<title>(.*?)</title>", page, re.S)
if not title or html.unescape(title.group(1)) != name:
    bad(f"the home page's <title> is {title and title.group(1)!r}, not {name!r}")
if f'aria-label="{html.escape(name, quote=True)}"' not in page and name not in text(page):
    bad(f"the header does not carry the site's name {name!r}")
if "Latest" not in text(page):
    bad("the home page does not list the latest posts")
if "TailwindBlog" in page or "tailwind-blog" in page:
    bad("the home page still carries the baseline's name")
if "https://github.com/timlrx/tailwind-nextjs-starter-blog" not in page:
    bad("the footer no longer credits the template (Tailwind Nextjs Theme)")
csp = headers.get("content-security-policy") or ""
if "default-src 'self'" not in csp or headers.get("x-frame-options") != "DENY":
    bad(f"the template's security headers are missing: CSP {csp[:40]!r}, X-Frame-Options {headers.get('x-frame-options')!r}")

# Every page the template has: the blog with its pages, tags, projects, about,
# a post (with its edit link on the site's own repository), the 404.
for path, want in (("/blog/", 200), ("/blog/page/2/", 200), ("/tags/", 200), ("/tags/next-js/", 200),
                   ("/projects/", 200), ("/about/", 200), ("/blog/no-such-post/", 404),
                   ("/robots.txt", 200), ("/static/images/logo.png", 200)):
    s, _, _ = get(path)
    if s != want:
        bad(f"{path} answered {s}, want {want}")
s, _, body = get("/blog/code-sample/")
post = body.decode()
if s != 200 or "<h1" not in post:
    bad(f"/blog/code-sample/ answered {s}")
if f"https://github.com/{org}/{repo}/blob/main/apps/web/data/blog/code-sample.md" not in post:
    bad(f"the post's 'View on GitHub' link is not on github.com/{org}/{repo}/…/apps/web/data/blog/")
s, _, body = get("/blog/")
if s == 200 and not re.search(r'href="/blog/[a-z0-9-]+/?"', body.decode()):
    bad("/blog/ lists no posts")

# The feeds the build writes: the site's channel, absolute item links on the
# origin the stage lane built for, and a feed per tag.
s, headers, body = get("/feed.xml")
try:
    channel = ET.fromstring(body).find("channel")
    if channel.findtext("title") != name:
        bad(f"the feed's channel title is {channel.findtext('title')!r}, not {name!r}")
    links = [i.findtext("link") for i in channel.findall("item")]
    if not links or not all(l.startswith(origin + "/blog/") for l in links):
        bad(f"the feed's item links are not absolute on {origin}: {links[:3]}")
except ET.ParseError as e:
    bad(f"/feed.xml is not well-formed XML ({e}) — a site name with an & must be escaped")
s, _, body = get("/tags/next-js/feed.xml")
if s != 200 or b"<rss" not in body:
    bad(f"/tags/next-js/feed.xml answered {s}")

# The search index the Contentlayer build writes (kbar).
s, _, body = get("/search.json")
try:
    docs = json.loads(body)
    if s != 200 or not docs or not all("slug" in d and "title" in d for d in docs):
        bad(f"/search.json answered {s} without the posts")
except ValueError:
    bad("/search.json is not JSON")

# The sitemap, absolute on the origin the stage lane built for.
s, _, body = get("/sitemap.xml")
locs = re.findall(r"<loc>(.*?)</loc>", body.decode())
if not locs or not all(l.startswith(origin) for l in locs):
    bad(f"the sitemap is not absolute on {origin}: {locs[:3]}")

# The newsletter route runs in the Worker: with no provider key it is
# refused by the provider, not by the Worker.
s, _, body = get("/api/newsletter/", "POST", json.dumps({"email": "a@example.com"}).encode())
if s in (404, 405) or b"error" not in body:
    bad(f"POST /api/newsletter/ answered {s}: {body[:80]!r}")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, the blog and its pages, tags, projects, about, a post, a 404, the feeds, the search index, the sitemap and the newsletter route — the site's own, on {origin}")
PY

echo "e2e.test.sh: ok"
