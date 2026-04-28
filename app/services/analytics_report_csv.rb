# Creates and renders a CSV of Analytics data for an Issuer by Month
class AnalyticsReportCsv
  DEFAULT_HEADERS = ['Friendly Name', 'Issuer', 'Month'].freeze
  attr_reader :report_data

  def initialize(report_data)
    @report_data = report_data
  end

  def render_in(view_context)
    view_context.render body: report_data_csv
  end

  def format
    :csv
  end

  private

  def report_data_csv
    month = report_data.report_information['month_start_calendar_id']
    friendly_name = report_data.provider_information['service_provider_name']

    CSV.generate do |csv|
      csv << DEFAULT_HEADERS.concat(data_headers)
      csv << [friendly_name, issuer, month].concat(data_values)
    end
  end

  def data_headers
    report_data.data.map { |d| d[0] }
  end

  def data_values
    report_data.data.map { |d| d[1] }
  end
end
