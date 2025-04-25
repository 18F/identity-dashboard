// Export the custom router and its utilities
export { Router, Link, route, getFullPath } from "./src/router";
export {
  Accordion,
  Header,
  Page,
  PlotComponent,
  ReportFilterControls,
  DailyRegistrationsReport,
  DailyDropOffsReport,
  DailyDropoffsLineChart,
  AccountDeletionsReport,
  DailyAuthsReport,
} from "./src/components";

export {
    default as createReportRoute, 
} from "./src/routes/report-route";

// Export the main Routes component (adjust the path if needed)
export { Routes } from "./src/routes";

// Optionally, export other reusable components or utilities
// Example: Export all components from a components directory
// export * from "./components"; // Replace with the actual path to your components

// Example: Export data models or utilities
// export * from "./data"; // Replace with the actual path to your data models
