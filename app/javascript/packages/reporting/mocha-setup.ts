import { h, Fragment } from "preact";

globalThis.h = h;
globalThis.Fragment = Fragment;

require.extensions[".svg"] = () => "";
