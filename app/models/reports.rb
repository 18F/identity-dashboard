# This class ingests report data from the data warehouse and breaks down the metadata such as
# date range and service provider details.
#
# It then passes off to child classes any calculating or derived statistics, handling of mapping
# field names to friendly names, and other concerns about prepping the data to be ready to display.
class Reports
  # This is here to enable errors
  include ActiveModel::Model

  EARLIEST_REPORT_DATE = Date.new(2025, 10, 1).freeze

  attr_reader :issuer, :chosen_date

  # @param configs [Array] of ServiceProvider records
  # @return [Hash<String, Array<String>>] issuer => monthly report date strings
  #   (newest first), computed from each service provider's first full month
  #   on the prod portal
  def self.available_dates(configs)
    configs.index_by(&:issuer).transform_values { |sp| monthly_dates_for(sp) }
  end

  def self.list_all_reports(user)
    issuers = user.report_scoped_sps.map(&:issuer)
    AnalyticsReportStorage.list_by_issuer(issuers)
  end

  # @return [Array<String>] monthly date strings (newest first) from the
  #   current month back through start_date
  def self.monthly_dates_since(start_date)
    current = Date.current.beginning_of_month
    dates = []
    while current >= start_date
      dates << current.strftime('%F')
      current = current.prev_month
    end
    dates
  end

  def self.monthly_dates_for(service_provider)
    start_date = [
      service_provider.created_at.to_date.beginning_of_month + 1.month,
      EARLIEST_REPORT_DATE,
    ].max
    monthly_dates_since(start_date)
  end
  private_class_method :monthly_dates_for

  def initialize(analytic)
    @issuer = analytic.config&.issuer
    @chosen_date = DateTime.parse(analytic.date) if analytic.date_valid?
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

  def data_valid?
    return true if data.keys.any?

    errors.add(:base, I18n.t('reports.errors.no_data'))
    false
  end

  def fraud
    @fraud ||= Report::Fraud.new(self)
  end

  def usage
    @usage ||= Report::Usage.new(self)
  end

  def authentication
    @authentication ||= Report::Authentication.new(self)
  end

  def idv
    @idv ||= Report::IdV.new(self)
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
