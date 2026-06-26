# This class ingests report data from the data warehouse and breaks down the metadata such as
# date range and service provider details.
#
# It then passes off to child classes any calculating or derived statistics, handling of mapping
# field names to friendly names, and other concerns about prepping the data to be ready to display.
class Reports
  attr_reader :issuer, :chosen_date

  # @param configs [Array] of ServiceProvider records
  # @param user [User] usually the `current_user`
  def self.available_dates(configs, user)
    issuers = configs.map(&:issuer)
    reports = list_all_reports(user).filter { |key| issuers.include?(key) }

    reports.transform_values do |values|
      values.map do |report|
        File.basename(report.key, File.extname(report.key))
      end
    end.to_h
  end

  def self.list_all_reports(user)
    issuers = user.scoped_service_providers.map(&:issuer)
    AnalyticsReportStorage.list_by_issuer(issuers)
  end

  private_class_method :list_all_reports

  def initialize(analytic)
    @issuer = analytic.config&.issuer
    @chosen_date = DateTime.parse(analytic.date) if analytic.valid_date?
    @chosen_date ||= DateTime.now
    @storage = AnalyticsReportStorage.new(issuer, chosen_date_as_string)
    @raw_data = unwrap(@storage.fetch)
  end

  def time_interval_size
    return 'month' if @storage.time_interval == 'monthly'
    return 'week' if @storage.time_interval == 'weekly'

    raise ArgumentError
  end

  def data
    return {} unless has_raw_data?

    @data ||= @raw_data['data'] || {}
  end

  def fraud
    @fraud ||= Reports::Fraud.new(self)
  end

  def usage
    @usage ||= Reports::Usage.new(self)
  end

  def idv
    @idv ||= Reports::IdV.new(self)
  end

  # Public so the view can check if report data was found
  # and display "Data not available for this month" when it wasn't
  def has_raw_data?
    @raw_data.present? && @raw_data.any?
  end

  def service_provider_name
    provider_information['service_provider_name'].to_s
  end

  # rubocop:disable Rails/Delegate
  def report_information_present?
    report_information.present?
  end
  # rubocop:enable Rails/Delegate

  def formatted_period_start_date
    Date.parse(report_information['period_start_date']).strftime('%Y-%m-%d')
  end

  def period_calendar_id
    report_information['period_calendar_id']
  end

  private

  def provider_information
    return {} unless has_raw_data?

    @provider_information || @raw_data['provider_information']
  end

  def report_information
    return {} unless has_raw_data?

    @report_information || @raw_data['report_information']
  end

  def chosen_date_as_string
    chosen_date.beginning_of_month.strftime('%F')
  end

  # Unwrap nested arrays from report JSON:
  # [[{hash}]] or [{hash}] -> {hash}
  def unwrap(data)
    data = data[0] while data.is_a?(Array)
    data || {}
  end
end
