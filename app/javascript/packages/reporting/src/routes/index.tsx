import { VNode } from "preact";
import { Control } from "../components/report-filter-controls";
import DailyAuthsReport from "../components/daily-auths-report";
import DailyDropffsReport from "../components/daily-dropoffs-report";
import ProofingOverTimeReport from "../components/proofing-over-time-report";
import DailyRegistrationsReport from "../components/daily-registrations-report";
import AccountDeletionsReport from "../components/account-deletions-report";
import { Router } from "../router";
import HomeRoute from "./home-route";
import createReportRoute, { ReportRoute } from "./report-route";
import { Scale } from "../contexts/report-filter-context";
import ALL_ROUTES from "./all";

/**
 * Requires that all keys in ALL_ROUTES have a matching key in this object
 */
type ReportRoutes = Record<keyof typeof ALL_ROUTES, ReportRoute>;

const reportRoutes: ReportRoutes = {
  "/daily-auths-report/": createReportRoute(DailyAuthsReport, {
    controls: [Control.IAL],
  }),
  "/daily-dropoffs-report/": createReportRoute(DailyDropffsReport, {
    controls: [Control.FUNNEL_MODE, Control.SCALE],
  }),
  "/proofing-over-time/": createReportRoute(ProofingOverTimeReport, {
    controls: [Control.FUNNEL_MODE, Control.SCALE, Control.TIME_BUCKET],
    defaultTimeRangeWeekOffset: -3,
    defaultScale: Scale.PERCENT,
  }),
  "/": HomeRoute,
  "/daily-registrations-report/": createReportRoute(DailyRegistrationsReport, {
    controls: [Control.CUMULATIVE],
  }),
  "/account-deletions-report/": createReportRoute(AccountDeletionsReport, {
    defaultTimeRangeWeekOffset: -16,
  }),
};

export function Routes(): VNode {
  return (
    <Router>
      {Object.entries(reportRoutes).map(([path, Component]) => (
        <Component path={path as keyof ReportRoutes} />
      ))}
    </Router>
  );
}
