import { utcFormat } from "d3-time-format";

const yearFormat = utcFormat("%Y");
const yearMonthDayFormat = utcFormat("%Y-%m-%d");

function domain(env: string): string {
  switch (env) {
    case "local":
      return "";
    case "prod":
    case "staging":
    case "dm":
      return `https://public-reporting-data.${env}.login.gov`;
    default:
      return `https://public-reporting-data.${env.replace(/[^a-z]/gi, "")}.identitysandbox.gov`;
  }
}

interface PathParameters {
  reportName: string;
  date: Date;
  env: string;
  extension?: string;
}

function path({ reportName, date, env, extension = "json" }: PathParameters): string {
  const year = yearFormat(date);
  const day = yearMonthDayFormat(date);

  // ex: /prod/daily-auths-report/2021/2021-07-27.daily-auths-report.json
  return `${domain(env)}/${env}/${reportName}/${year}/${day}.${reportName}.${extension}`;
}

export { path };
