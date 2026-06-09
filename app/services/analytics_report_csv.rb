# Creates and renders a CSV of Analytics data for an Issuer by Month
class AnalyticsReportCsv
  HEADER_ROW = ['', 'Quarterly', 'Monthly', 'Weekly'].freeze
  attr_reader :report_data

  def initialize(report_data)
    @report_data = report_data
  end

  def report_data_csv
    return headers_only if report_data.report_information.blank?

    period_start_date = report_data.report_information['period_start_date']
    start_date = Date.parse(period_start_date).strftime('%Y-%m-%d')

    CSV.generate(headers: true) do |csv|
      csv << HEADER_ROW
      csv << ['Start Date', '', start_date, '']
      report_data.data.each do |arr|
        csv << [arr[0], '', arr[1], '']
      end
    end
  end

  def filename
    period_id = report_data.report_information['period_calendar_id']
    friendly_name = report_data.provider_information['service_provider_name'].to_s

    "logingov_#{friendly_name.parameterize.underscore}_#{period_id}.csv"
  end

  private

  def headers_only
    CSV.generate(headers: true) do |csv|
      csv << HEADER_ROW
    end
  end
end
