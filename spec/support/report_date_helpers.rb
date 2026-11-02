# The most recent month with report data. Last month only becomes available
# on or after the configured report_turnover_day.
def most_recent_report_date
  date = Date.current.beginning_of_month.prev_month
  date = date.prev_month if Date.current.day < IdentityConfig.store.report_turnover_day
  date.strftime('%F')
end
