import { expect } from "chai";
import { kebabCase } from "./strings";

describe("strings", () => {
  describe("#kebabCase", () => {
    expect(kebabCase("U.S. Agency for X")).to.equal("u-s-agency-for-x");
  });
});
