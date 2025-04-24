import { VNode } from "preact";
import { useRef, useContext } from "preact/hooks";
import { utcFormat } from "d3-time-format";
import { utcWeek, CountableTimeInterval } from "d3-time";
import {
  ReportFilterContext,
  DEFAULT_ENV,
  Scale,
  FunnelMode,
  TimeBucket,
} from "../contexts/report-filter-context";
import { AgenciesContext } from "../contexts/agencies-context";

const yearMonthDayFormat = utcFormat("%Y-%m-%d");

/**
 * Controls on the form that can be opted into
 */
enum Control {
  IAL = "ial",
  FUNNEL_MODE = "funnel_mode",
  SCALE = "scale",
  AGENCY = "agency",
  BY_AGENCY = "by_agency",
  TIME_BUCKET = "time_bucket",
  CUMULATIVE = "cumulative",
}

interface ReportFilterControlsProps {
  controls?: Control[];
}

function ReportFilterControls({ controls }: ReportFilterControlsProps): VNode {
  const {
    start,
    finish,
    agency,
    ial,
    env,
    funnelMode,
    scale,
    byAgency,
    extra,
    timeBucket,
    cumulative,
    setParameters,
  } = useContext(ReportFilterContext);
  const { agencies } = useContext(AgenciesContext);
  const formRef = useRef(null as HTMLFormElement | null);

  function update(event: Event, overrideFormData: Record<string, string> = {}) {
    const form = formRef.current;
    if (!form) {
      return;
    }

    const formData = new FormData(form);
    Object.entries(overrideFormData).forEach(([key, value]) => formData.set(key, String(value)));
    setParameters(Object.fromEntries(formData) as Record<string, string>);
    event.preventDefault();
  }

  function updateTimeRange(interval: CountableTimeInterval, offset: number) {
    return function (event: Event) {
      return update(event, {
        start: yearMonthDayFormat(interval.offset(start, offset)),
        finish: yearMonthDayFormat(interval.offset(finish, offset)),
      });
    };
  }

  return (
    <form ref={formRef} onChange={update} className="usa-form-full-width">
      <div className="grid-container padding-0">
        <div className="grid-row grid-gap">
          <div className="tablet:grid-col-6">
            <fieldset className="usa-fieldset">
              <legend className="usa-legend">Time Range</legend>
              <div className="grid-row grid-gap">
                <div className="tablet:grid-col-6">
                  <label className="usa-label">
                    Start
                    <input
                      type="date"
                      name="start"
                      value={yearMonthDayFormat(start)}
                      className="usa-input"
                    />
                  </label>
                </div>
                <div className="tablet:grid-col-6">
                  <label className="usa-label">
                    Finish
                    <input
                      type="date"
                      name="finish"
                      value={yearMonthDayFormat(finish)}
                      className="usa-input"
                    />
                  </label>
                </div>
              </div>
              <div className="margin-top-2 grid-row grid-gap">
                <div className="tablet:grid-col-6">
                  <button
                    type="button"
                    className="usa-button usa-button--full-width margin-bottom-1"
                    onClick={updateTimeRange(utcWeek, -1)}
                  >
                    &larr; Previous Week
                  </button>
                </div>
                <div className="tablet:grid-col-6">
                  <button
                    type="button"
                    className="usa-button usa-button--full-width"
                    onClick={updateTimeRange(utcWeek, +1)}
                  >
                    Next Week &rarr;
                  </button>
                </div>
              </div>
            </fieldset>
            {controls?.includes(Control.TIME_BUCKET) && (
              <fieldset className="usa-fieldset">
                <legend className="usa-legend">Time Bucket</legend>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="time-bucket-day"
                    name="timeBucket"
                    value="day"
                    checked={timeBucket === TimeBucket.DAY}
                    className="usa-radio__input"
                  />
                  <label htmlFor="time-bucket-day" className="usa-label usa-radio__label">
                    Day
                  </label>
                </div>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="time-bucket-week"
                    name="timeBucket"
                    value="week"
                    checked={!timeBucket || timeBucket === TimeBucket.WEEK}
                    className="usa-radio__input"
                  />
                  <label htmlFor="time-bucket-week" className="usa-label usa-radio__label">
                    Week
                  </label>
                </div>
              </fieldset>
            )}
            {(controls?.includes(Control.AGENCY) || agency) && (
              <fieldset className="usa-fieldset">
                <legend className="usa-legend" id="agency-legend">
                  Agency
                </legend>
                <select name="agency" className="usa-select" aria-labelledby="agency-legend">
                  <option value="">All</option>
                  <optgroup label="Agencies">
                    {agencies.map((a) => (
                      <option value={a} selected={a === agency}>
                        {a}
                      </option>
                    ))}
                  </optgroup>
                </select>
              </fieldset>
            )}
          </div>
          <div className="tablet:grid-col-6">
            {controls?.includes(Control.IAL) && (
              <fieldset className="usa-fieldset">
                <legend className="usa-legend">Identity</legend>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="ial-1"
                    name="ial"
                    value="1"
                    checked={ial === 1}
                    className="usa-radio__input"
                  />
                  <label htmlFor="ial-1" className="usa-label usa-radio__label">
                    Authentication
                  </label>
                </div>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="ial-2"
                    name="ial"
                    value="2"
                    checked={ial === 2}
                    className="usa-radio__input"
                  />
                  <label htmlFor="ial-2" className="usa-label usa-radio__label">
                    Proofing
                  </label>
                </div>
              </fieldset>
            )}
            {controls?.includes(Control.FUNNEL_MODE) && (
              <fieldset className="usa-fieldset">
                <legend className="usa-legend">Funnel Mode</legend>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="funnel-mode-blanket"
                    name="funnelMode"
                    value={FunnelMode.BLANKET}
                    checked={funnelMode === FunnelMode.BLANKET}
                    className="usa-radio__input"
                    aria-describedby="funnel-mode-blanket-desc"
                  />
                  <label htmlFor="funnel-mode-blanket" className="usa-label usa-radio__label">
                    Blanket
                  </label>
                  <span className="margin-left-1" id="funnel-mode-blanket-desc">
                    The funnel starts at the welcome step
                  </span>
                </div>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="funnel-mode-actual"
                    name="funnelMode"
                    value={FunnelMode.ACTUAL}
                    checked={funnelMode === FunnelMode.ACTUAL}
                    className="usa-radio__input"
                    aria-describedby="funnel-mode-actual-desc"
                  />
                  <label htmlFor="funnel-mode-actual" className="usa-label usa-radio__label">
                    Actual
                  </label>
                  <span className="margin-left-1" id="funnel-mode-actual-desc">
                    The funnel starts at the image submit step
                  </span>
                </div>
              </fieldset>
            )}
            {controls?.includes(Control.SCALE) && (
              <fieldset className="usa-fieldset">
                <legend className="usa-legend">Scale</legend>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="scale-count"
                    name="scale"
                    value={Scale.COUNT}
                    checked={scale === Scale.COUNT}
                    className="usa-radio__input"
                  />
                  <label htmlFor="scale-count" className="usa-label usa-radio__label">
                    Count
                  </label>
                </div>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="scale-percent"
                    name="scale"
                    value={Scale.PERCENT}
                    checked={scale === Scale.PERCENT}
                    className="usa-radio__input"
                  />
                  <label htmlFor="scale-percent" className="usa-label usa-radio__label">
                    Percent
                  </label>
                </div>
              </fieldset>
            )}
            {controls?.includes(Control.BY_AGENCY) && (
              <fieldset className="usa-fieldset">
                <legend className="usa-legend">Break out by Agency</legend>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="byagency-on"
                    name="byAgency"
                    value="on"
                    checked={byAgency}
                    className="usa-radio__input"
                  />
                  <label htmlFor="byagency-on" className="usa-label usa-radio__label">
                    Enabled
                  </label>
                </div>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="byagency-off"
                    name="byAgency"
                    value="off"
                    checked={!byAgency}
                    className="usa-radio__input"
                  />
                  <label htmlFor="byagency-off" className="usa-label usa-radio__label">
                    Disabled
                  </label>
                </div>
              </fieldset>
            )}
            {controls?.includes(Control.CUMULATIVE) && (
              <fieldset className="usa-fieldset">
                <legend className="usa-legend">Cumulative</legend>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="cumulative-on"
                    name="cumulative"
                    value="on"
                    checked={cumulative}
                    className="usa-radio__input"
                  />
                  <label htmlFor="cumulative-on" className="usa-label usa-radio__label">
                    Enabled
                  </label>
                </div>
                <div className="usa-radio">
                  <input
                    type="radio"
                    id="cumulative-off"
                    name="cumulative"
                    value="off"
                    checked={!cumulative}
                    className="usa-radio__input"
                  />
                  <label htmlFor="cumulative-off" className="usa-label usa-radio__label">
                    Disabled
                  </label>
                </div>
              </fieldset>
            )}
          </div>
        </div>
        <div className="grid-row margin-top-2">
          <div className="tablet:grid-col-6">
            <div>
              <a href="?" className="usa-button usa-button--outline">
                Reset
              </a>
            </div>
          </div>
        </div>
      </div>
      {env !== DEFAULT_ENV && <input type="hidden" name="env" value={env} />}
      {extra && <input type="hidden" name="extra" value="true" />}
    </form>
  );
}

export default ReportFilterControls;
export { ReportFilterControlsProps, Control };
