import { expect } from "chai";
import { formatSIDropTrailingZeroes } from "./formats";

describe("formats", () => {
  describe("#formatSIDropTrailingZeroes", () => {
    it("leaves small numbers alone", () => {
      expect(formatSIDropTrailingZeroes(1)).to.eq("1");
      expect(formatSIDropTrailingZeroes(0.5)).to.eq("0.5");
    });

    it("formats with an SI prefix", () => {
      expect(formatSIDropTrailingZeroes(1_230_000)).to.eq("1.2M");
    });

    it("drops trailing zeroes", () => {
      expect(formatSIDropTrailingZeroes(1_000.0)).to.eq("1k");
    });
  });
});
