import preact from "@preact/preset-vite";
import type { UserConfig } from "vite";

const config: UserConfig = {
  plugins: [preact()],
  build: {
    outDir: "_site",
    sourcemap: true,
  },
  publicDir: "data",
};

export default config;
