import { VNode } from "preact";
import { Control } from "../components/report-filter-controls";
import DailyAuthsReport from "../components/daily-auths-report";
import { Router } from "../router";
import createReportRoute, { ReportRoute } from "./new-report-route";
import {NEW_ROUTES} from "./all";

type ReportRoutes = Record<keyof typeof NEW_ROUTES, ReportRoute>;

const reportRoutes: ReportRoutes = {
  "/reports": createReportRoute(DailyAuthsReport, {
    controls: [Control.IAL],
  }),
};

export function Routes(): VNode {
  console.log("Report Routes:", reportRoutes["/reports"]);

  const Component = reportRoutes["/reports"];
  console.log("Executing Component for '/reports':", Component({ path: "/reports" }));

  return (
    <Router>
      {Object.entries(reportRoutes).map(([path, Component]) => (
        <Component path={path as keyof ReportRoutes} />
      ))}
    </Router>
  );
}
// export function Routes(): VNode {
//   const Component = reportRoutes["/reports"];
//   return (
//     <div>
//       <h1>Test Render</h1>
//       <Component path="/reports" />
//     </div>
//   );
// }