import { VNode } from "preact";
import { AgenciesContextProvider } from "../contexts/agencies-context";
import ReportFilterContextProvider from "../contexts/report-filter-context";
import ReportFilterControls, { Control } from "./report-filter-controls";
import { Scale, FunnelMode } from "../contexts/report-filter-context";

interface SingleReportWrapperProps {
  title: string;
  env?: string;
  controls?: Control[];
  start?: Date;
  finish?: Date;
  
  report: () => VNode;
}

const SingleReportWrapper = ({
  title,
  controls = [],
  start,
  finish,
  env,
  report: Report,
}: SingleReportWrapperProps): VNode => {
  // Ensure default values are properly handled  
  const defaultFinish = new Date();
  const defaultStart = new Date();
  defaultStart.setDate(defaultFinish.getDate() - 7);
  defaultFinish.setDate(defaultFinish.getDate() - 1);
  const defaultEnv = "prod"

  return (
    <div className="single-report-wrapper">
      <h1>{title}</h1>
      <AgenciesContextProvider>
        <ReportFilterContextProvider
          start={start ?? defaultStart}
          finish={finish ?? defaultFinish}
          ial={1} // Ensure 'ial' is dynamically configurable if needed
          env={env ?? defaultEnv} // Ensure 'env' is dynamically configurable if needed
          funnelMode={FunnelMode.BLANKET} // Ensure 'funnelMode' is dynamically configurable if needed
          scale={Scale.COUNT} // Ensure 'scale' is dynamically configurable if needed
          byAgency={false} // Ensure 'byAgency' is dynamically configurable if needed
          extra={false} // Ensure 'extra' is dynamically configurable if needed
        >
          <ReportFilterControls controls={controls} />
          <Report />
        </ReportFilterContextProvider>
      </AgenciesContextProvider>
    </div>
  );
};

export default SingleReportWrapper;