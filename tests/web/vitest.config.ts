import { defineConfig } from "vitest/config";
import * as path from "node:path";

const web = path.resolve(__dirname, "../../apps/web");

export default defineConfig({
  resolve: {
    alias: [
      { find: /^app\//, replacement: web + "/app/" },
      { find: /^data\//, replacement: web + "/data/" },
    ],
  },
  test: {
    include: ["src/**/*.test.ts"],
    environment: "node",
  },
});
