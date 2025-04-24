import { mkdir, copyFile } from "fs/promises";
import { join } from "path";

import ALL_ROUTES from "../src/routes/all";

const reportRoutes = Object.keys(ALL_ROUTES).filter((route) => route !== "/");

Promise.all(
  reportRoutes.map(async (path) => {
    const dir = join("_site", path);
    await mkdir(dir, { recursive: true });
    await copyFile("_site/index.html", join(dir, "index.html"));
  })
);
