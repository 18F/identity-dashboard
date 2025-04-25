import { h, render } from 'preact';
import { DailyAuthsReport } from '@18f/identity-reporting';


render(<DailyAuthsReport />, document.getElementById("daily-auths-report") as HTMLElement);