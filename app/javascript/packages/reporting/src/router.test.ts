import { expect } from "chai";
import { getFullPath } from "./router";

describe("router", () => {
  describe("#getFullPath", () => {
    it("prepends the base path to the path", () => {
      const path = "/foobar.html";
      const basePath = "/some/nested/directory";
      expect(getFullPath(path, basePath)).to.eq("/some/nested/directory/foobar.html");
    });

    it("does not add extra slashes when basePath is blank", () => {
      const path = "/foo/bar.html";
      const basePath = "";
      expect(getFullPath(path, basePath)).to.eq("/foo/bar.html");
    });

    it("does not add the base path when it is already there", () => {
      const path = "/some/prefix/foo/bar.html";
      const basePath = "/some/prefix";
      expect(getFullPath(path, basePath)).to.eq(path);
    });

    it("does not remove a trailing slash", () => {
      const path = "/foo/";
      const basePath = "/some/prefix";
      expect(getFullPath(path, basePath)).to.eq("/some/prefix/foo/");
    });
  });
});
