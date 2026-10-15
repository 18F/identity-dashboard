# Creates and renders a CSV of Analytics data for an Issuer by Month
class AnalyticsReportCsv < Report::Base
  HEADER_ROW = ['', 'Description', 'Quarterly', 'Monthly', 'Weekly'].freeze
  attr_reader :report_data

  def initialize(report_data)
    @report_data = report_data
    super
  end

  def report_data_csv
    return headers_only unless report_data.report_information_present?

    full_csv
  end

  def filename
    period_id = report_data.period_calendar_id
    friendly_name = report_data.service_provider_name

    "logingov_#{friendly_name.parameterize.underscore}_#{period_id}.csv"
  end

  private

  def headers_only
    CSV.generate(headers: true) do |csv|
      csv << HEADER_ROW
    end
  end

  def full_csv
    monthly_start_date = report_data.formatted_period_start_date

    CSV.generate(headers: true) do |csv|
      csv << HEADER_ROW
      csv << ['Start Date', description('period_date_id'), '', monthly_start_date, '']
      labeled_keys.each do |key|
        csv << [I18n.t("reports.#{key}"), description(key), '', data[key], '']
      end
    end
  end

  def description(key)
    I18n.t("reports.descriptions.#{key}", default: '')
  end
end
