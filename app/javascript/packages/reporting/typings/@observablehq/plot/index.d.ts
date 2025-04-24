/* eslint-disable @typescript-eslint/no-explicit-any */
declare module "@observablehq/plot" {
  export function plot(args: any): HTMLElement;
  export function rectY(a: any, b: any): any;
  export function binX(a: any, b: any): any;
  export function binY(a: any, b: any): any;
  export function ruleY(a: any, b?: any): any;
  export function line(a: any, b: any): any;
  export function lineY(a: any, b: any): any;
  export function text(a: any, b?: any): any;
}
