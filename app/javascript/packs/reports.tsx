// // import { render } from "preact";
// // import SingleReportWrapper from "../packages/reporting/src/components/single-report-wrapper";
// // import { DailyAuthsReport } from "@18f/identity-reporting";
// // import { Control } from "../packages/reporting/src/components/report-filter-controls";

// // render(
// //   <SingleReportWrapper
// //     title="Daily Auths Report"
// //     controls={[Control.IAL, Control.AGENCY]}
// //     env="prod"
// //     report={DailyAuthsReport} // The report component
// //   />,
// //   document.getElementById("app") as HTMLElement
// // );

import { render } from "preact";
import { useState } from "preact/hooks";
import {
  wrapSingleReport,
  DailyAuthsReport,
  FilterControl,
  NewRoutes,
} from "@18f/identity-reporting";

const Reports = {
  DailyAuths: wrapSingleReport(DailyAuthsReport, {
    controls: [FilterControl.IAL],
    defaultTimeRangeWeekOffset: 0, // Adjust as needed
  }),
};

// const App = () => {
//   const [key, setKey] = useState(0);

//   const refreshReport = () => setKey((prevKey) => prevKey + 1);

//   return (
// <Reports.DailyAuths path="/" />
//   );
// };

// Render the App component into a specific DOM element
console.log(DailyAuthsReport);

render(<Reports.DailyAuths />, 
  document.getElementById("app") as HTMLElement);

// import { render } from "preact";
// import { NewRoutes} from "@18f/identity-reporting";

// const rootElement = document.getElementById("app");

// if (!rootElement) {
//   console.error("Root element with id 'app' not found.");
// } else {
//   console.log("Rendering NewRoutes...");
//   render(<NewRoutes />, rootElement);
// }
