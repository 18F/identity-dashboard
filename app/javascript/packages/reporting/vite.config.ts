import preact from "@preact/preset-vite";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [preact()],
  build: {
    outDir: "_site",
    sourcemap: true,
    modulePreload: {
      polyfill: false, // Optional: Disable polyfills for modern browsers
    },
  },
  publicDir: "data",
  esbuild: {
    target: "esnext", // Ensure modern ES module syntax
  },
});