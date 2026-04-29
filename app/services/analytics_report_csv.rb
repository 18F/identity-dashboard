# Creates and renders a CSV of Analytics data for an Issuer by Month
class AnalyticsReportCsv
  HEADER_ROW = ['', 'Quarterly', 'Monthly', 'Weekly'].freeze
  attr_reader :report_data

  def initialize(report_data)
    @report_data = report_data
  end

  def report_data_csv
    month = report_data['report_information']['month_start_date_actual']

    CSV.generate(headers: true) do |csv|
      csv << HEADER_ROW
      csv << ['Start Date', '', month, '']
      inner_data.each do |arr|
        label = I18n.t("reports.#{arr[0]}") || arr[0]
        csv << [label, '', arr[1], '']
      end
    end
  end

  def filename
    month_id = report_data['report_information']['month_start_calendar_id']
    friendly_name = report_data['provider_information']['service_provider_name']

    "logingov_#{friendly_name.parameterize.underscore}_#{month_id}.csv"
  end

  private

  def inner_data
    @inner_data ||= report_data['data']
  end
end
