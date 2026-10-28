// SVGs are imported as React components through @svgr/webpack
// (next.config.js). Next declares `*.svg` in next-env.d.ts, which next
// writes at build time and the repository does not carry, so `tsc` on a
// fresh checkout reads the same declaration from here.
declare module '*.svg' {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const content: any
  export default content
}
