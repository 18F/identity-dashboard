import { format } from "d3-format";
import { utcFormat, utcParse } from "d3-time-format";

export const yearMonthDayFormat = utcFormat("%Y-%m-%d");

export const formatWithCommas = format(",");

const formatSIPrefix = format(".2s");
const formatDecimal = format(".2");
export const formatSIDropTrailingZeroes = (d: number): string =>
  d >= 1 ? formatSIPrefix(d).replace(/\.0+/, "") : formatDecimal(d);

export const formatAsPercent = format(".0%");
export const formatAsDecimalPercent = format(".2%");

export const yearMonthDayParse = utcParse("%Y-%m-%d") as (s: string) => Date;
