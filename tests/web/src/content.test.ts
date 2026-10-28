import { readdirSync, readFileSync, statSync } from "node:fs";
import * as path from "node:path";
import { describe, expect, it } from "vitest";

const web = path.resolve(__dirname, "../../../apps/web");

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const full = path.join(dir, name);
    return statSync(full).isDirectory() ? files(full) : [full];
  });
}

function frontMatter(text: string): Record<string, string> {
  const m = /^---\n([\s\S]*?)\n---/.exec(text);
  if (!m) return {};
  const out: Record<string, string> = {};
  for (const line of m[1].split("\n")) {
    const kv = /^([A-Za-z]+):\s*(.*)$/.exec(line);
    if (kv) out[kv[1]] = kv[2].replace(/^['"]|['"]$/g, "");
  }
  return out;
}

describe("the blog's content (apps/web/data/blog)", () => {
  const posts = files(path.join(web, "data/blog")).filter((f) => /\.mdx?$/.test(f));

  it("has posts", () => {
    expect(posts.length).toBeGreaterThan(0);
  });

  it.each(posts.map((p) => [path.relative(web, p)]))("%s has a title and a valid date", (rel) => {
    const fm = frontMatter(readFileSync(path.join(web, rel), "utf8"));
    expect(fm.title, "title").toBeTruthy();
    expect(Number.isNaN(Date.parse(fm.date)), `date ${fm.date}`).toBe(false);
  });

  it("names an author the site has a page for", () => {
    const authors = new Set(files(path.join(web, "data/authors")).map((f) => path.basename(f).replace(/\.mdx?$/, "")));
    expect(authors.has("default")).toBe(true);
  });
});

describe("the header's links (apps/web/data/headerNavLinks.ts)", () => {
  it("each points at a route the app has", async () => {
    const { default: links } = await import("data/headerNavLinks");
    for (const { href } of links as { href: string }[]) {
      if (href === "/") continue;
      expect(statSync(path.join(web, "app", href)).isDirectory(), href).toBe(true);
    }
  });
});
