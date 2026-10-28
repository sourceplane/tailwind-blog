import { afterEach, describe, expect, it, vi } from "vitest";

// data/siteMetadata.js reads NEXT_PUBLIC_SITE_URL when it is loaded, so each
// case loads a fresh copy.
async function load(env: Record<string, string | undefined> = {}) {
  vi.resetModules();
  for (const [k, v] of Object.entries(env)) {
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
  const mod = await import("data/siteMetadata.js");
  return (mod.default ?? mod) as Record<string, unknown>;
}

afterEach(() => {
  delete process.env.NEXT_PUBLIC_SITE_URL;
});

describe("site identity (apps/web/data/siteMetadata.js)", () => {
  it("names the site once: the title and the header are the same name", async () => {
    const meta = await load();
    expect(String(meta.title).trim()).not.toBe("");
    expect(meta.headerTitle).toBe(meta.title);
  });

  it("links its own source repository", async () => {
    const meta = await load();
    expect(meta.siteRepo).toMatch(/^https:\/\/github\.com\/[A-Za-z0-9-]+\/[a-z0-9-]+$/);
  });

  it("builds absolute links for the origin the deploy names", async () => {
    expect((await load({ NEXT_PUBLIC_SITE_URL: "https://blog.example.org" })).siteUrl).toBe("https://blog.example.org");
    expect((await load({ NEXT_PUBLIC_SITE_URL: undefined })).siteUrl).toBe("http://localhost:3000");
  });
});
