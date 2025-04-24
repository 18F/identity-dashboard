import "./css/style.scss";

import { render } from "preact";
import { banner, accordion, navigation } from "identity-style-guide";
import { Routes } from "./routes";

[banner, accordion, navigation].forEach((component) => component.on());

render(<Routes />, document.getElementById("app") as HTMLElement);
