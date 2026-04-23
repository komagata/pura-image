import { defineConfig } from "vite";

export default defineConfig({
  base: "./",
  server: {
    fs: {
      allow: [".."]
    }
  },
  build: {
    target: "es2022",
    assetsInlineLimit: 0
  },
  assetsInclude: ["**/*.wasm"],
  optimizeDeps: {
    exclude: ["@ruby/wasm-wasi"]
  }
});
