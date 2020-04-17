import { JSDOM } from "jsdom";

const JSDOM_DEFAULT_HTML = `
<html>
  <body style='margin:0;'>
    <img
      src='https://media.giphy.com/media/e5kbmb3wX3J1S/source.gif'
      width='100%'
      height='100%'
    />
  </body>
</html>
`;

export const setupTestDOM = (initialHtml = JSDOM_DEFAULT_HTML) => {
  const dom = new JSDOM(initialHtml);
  global.window = dom.window;
  global.document = global.window.document;
};

export const teardDownTestDOM = () => {
  global.window = undefined;
  global.document = undefined;
};
