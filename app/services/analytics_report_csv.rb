# Creates and renders a CSV of Analytics data for an Issuer by Month
class AnalyticsReportCsv
  HEADER_ROW = ['', 'Quarterly', 'Monthly', 'Weekly'].freeze
  attr_reader :report_data

  def initialize(report_data)
    @report_data = report_data
  end

  def report_data_csv
    month = report_data.report_information['month_start_date_actual']

    CSV.generate(headers: true) do |csv|
      csv << HEADER_ROW
      csv << ['Start Date', '', month, '']
      report_data.data.each do |arr|
        csv << [arr[0], '', arr[1]]
      end
    end
  end

  def filename
    month_id = report_data.report_information['month_start_calendar_id']
    friendly_name = report_data.provider_information['service_provider_name']

    "Logingov_#{friendly_name.parameterize.underscore}_#{month_id}.csv"
  end
end
