import {Chart, registerables} from "chart.js/auto";
import a11yLegend from "chartjs-plugin-a11y-legend";

Chart.register(...registerables, a11yLegend);