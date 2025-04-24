import { VNode } from "preact";
import Markdown from "preact-markdown";
import { utcWeek, utcDay, CountableTimeInterval } from "d3-time";
import { ascending, rollup } from "d3-array";
import { FunnelMode, TimeBucket } from "../contexts/report-filter-context";
import {
  DailyDropoffsRow,
  funnelSteps,
  StepCount,
  toStepCounts,
} from "../models/daily-dropoffs-report-data";
import { formatAsPercent, formatWithCommas, yearMonthDayFormat } from "../formats";
import { TableData } from "./table";

interface StepCountEntry extends StepCount {
  date: Date;
  agency: string;
  issuer: string;
  friendlyName: string;
}

function flatten({
  data,
  funnelMode,
}: {
  funnelMode: FunnelMode;
  data: DailyDropoffsRow[];
}): StepCountEntry[] {
  const results = data.flatMap((row) => {
    const { start, agency: rowAgency, issuer, friendly_name: friendlyName } = row;

    return toStepCounts(row, funnelMode).map((stepCount) => ({
      date: start,
      issuer,
      friendlyName,
      agency: rowAgency,
      ...stepCount,
    }));
  });

  return results;
}

function bucketDates(data: DailyDropoffsRow[], interval: CountableTimeInterval): Date[] {
  return Array.from(new Set(data.map((row) => +interval.floor(row.start))))
    .map((ms) => new Date(ms))
    .sort((a, b) => ascending(a, b));
}

interface VerifiedTotal {
  verified: number;
  total: number;
}

const VERIFIED_TOTAL_ZERO: VerifiedTotal = { verified: 0, total: 0 };

function sumToTotalVerified(bin: DailyDropoffsRow[], funnelMode: FunnelMode): VerifiedTotal {
  const firstStep = funnelSteps(funnelMode)[0].key;

  return bin.reduce(
    ({ total, verified }, d) => ({ total: total + d[firstStep], verified: verified + d.verified }),
    VERIFIED_TOTAL_ZERO
  );
}

function sumOfTotalVerified(values: Map<any, VerifiedTotal>): VerifiedTotal {
  return Array.from(values).reduce(
    ({ total, verified }, [, d]) => ({ total: d.total + total, verified: d.verified + verified }),
    VERIFIED_TOTAL_ZERO
  );
}

function countAndPercent({ total, verified }: VerifiedTotal): [VNode, VNode] {
  const fraction = verified / total || 0;

  return [
    <span data-csv={verified}>{formatWithCommas(verified)}</span>,
    <span data-csv={fraction}>{formatAsPercent(fraction)}</span>,
  ];
}

function tabulateAll({
  data,
  timeBucket,
  funnelMode,
}: {
  data: DailyDropoffsRow[];
  timeBucket: TimeBucket;
  funnelMode: FunnelMode;
}): TableData {
  const interval = timeBucket === TimeBucket.WEEK ? utcWeek : utcDay;
  const dates = bucketDates(data, interval);

  const totalByDate = rollup(
    data,
    (bin) => sumToTotalVerified(bin, funnelMode),
    (d) => +interval.floor(d.start)
  );

  const body = [
    [
      "(All)",
      ...dates.flatMap((date) => countAndPercent(totalByDate.get(+date) || VERIFIED_TOTAL_ZERO)),
      ...countAndPercent(sumOfTotalVerified(totalByDate)),
    ],
  ];

  return {
    header: [
      "Agency",
      ...dates.map((date) => <th colSpan={2}>{yearMonthDayFormat(date)}</th>),
      <th colSpan={2}>Total</th>,
    ],
    body,
  };
}

function tabulateByAgency({
  data,
  timeBucket,
  funnelMode,
  color,
}: {
  data: DailyDropoffsRow[];
  timeBucket: TimeBucket;
  funnelMode: FunnelMode;
  color: (issuer: string) => string;
}): TableData {
  const interval = timeBucket === TimeBucket.WEEK ? utcWeek : utcDay;
  const dates = bucketDates(data, interval);

  const totalByAgencyByDate = rollup(
    data,
    (bin) => sumToTotalVerified(bin, funnelMode),
    (d) => d.agency,
    (d) => +interval.floor(d.start)
  );

  const header = [
    "Agency",
    ...dates.map((date) => <th colSpan={2}>{yearMonthDayFormat(date)}</th>),
    <th colSpan={2}>Total</th>,
  ];

  const body = Array.from(totalByAgencyByDate)
    .sort(([agencyA], [agencyB]) => ascending(agencyA, agencyB))
    .map(([agency, totalByDate]) => [
      <span data-csv={agency}>
        <span style={`color: ${color(agency)}`}>⬤ </span>
        {agency}
      </span>,
      ...dates.flatMap((date) => countAndPercent(totalByDate.get(+date) || VERIFIED_TOTAL_ZERO)),
      ...countAndPercent(sumOfTotalVerified(totalByDate)),
    ]);

  return {
    header,
    body,
  };
}

function tabulateByIssuer({
  data,
  timeBucket,
  funnelMode,
  color,
}: {
  data: DailyDropoffsRow[];
  timeBucket: TimeBucket;
  funnelMode: FunnelMode;
  color: (issuer: string) => string;
}): TableData {
  const interval = timeBucket === TimeBucket.WEEK ? utcWeek : utcDay;
  const dates = bucketDates(data, interval);

  const friendlyNameToIssuer = new Map(data.map((row) => [row.friendly_name, row.issuer]));

  const totalByAgencyByIssuerByDate = rollup(
    data,
    (bin) => sumToTotalVerified(bin, funnelMode),
    (d) => d.agency,
    (d) => d.friendly_name,
    (d) => +interval.floor(d.start)
  );

  const header = [
    "Agency",
    <span data-csv={["Issuer", "Friendly Name"]}>App</span>,
    ...dates.map((date) => <th colSpan={2}>{yearMonthDayFormat(date)}</th>),
    <th colSpan={2}>Total</th>,
  ];

  const body = Array.from(totalByAgencyByIssuerByDate)
    .sort(([agencyA], [agencyB]) => ascending(agencyA, agencyB))
    .flatMap(([agency, issuers]) =>
      Array.from(issuers)
        .sort(([friendlyNameA], [friendlyNameB]) => ascending(friendlyNameA, friendlyNameB))
        .map(([friendlyName, totalByDate]) => {
          const issuer = friendlyNameToIssuer.get(friendlyName);

          return [
            agency,
            <span title={issuer} data-csv={[issuer, friendlyName]}>
              <span style={`color: ${color(friendlyName)}`}>⬤ </span>
              {friendlyName}
            </span>,
            ...dates.flatMap((date) =>
              countAndPercent(totalByDate.get(+date) || VERIFIED_TOTAL_ZERO)
            ),
            ...countAndPercent(sumOfTotalVerified(totalByDate)),
          ];
        })
    );

  return {
    header,
    body,
  };
}

export default function ProofingOverTimeReport(): VNode {
  return (
    <div className="padding-bottom-5">
      <Markdown
        markdown={`
## This Report is Unavailable Right Now

We're investigating inconsistencies in the underlying data.
`}
      />
    </div>
  );
}

export { flatten, tabulateAll, tabulateByAgency, tabulateByIssuer };
