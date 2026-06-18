class AnalyticsController < ApplicationController # :nodoc:
  AVAILABLE_REPORTS = [Reports::Identity].freeze
  DEFAULT_GRAPH_OPTIONS = { download: true }.freeze
  EARLIEST_REPORT_DATE = Date.new(2025, 10, 1).freeze

  before_action -> { authorize analytic }
  after_action :verify_authorized
  after_action :verify_policy_scoped

  helper_method :all_app_options_string

  # /reports
  def index
    respond_to do |format|
      format.html { populate_data_for_html }
      format.csv do
        report = AnalyticsReportCsv.new(identity_report)
        send_data report.report_data_csv, filename: report.filename
      end
    end
  end

  def create
    if analytic.valid?
      redirect_to analytics_path(team: analytic.config.team, uuid: analytic.config.uuid,
                                 date: analytic.date) and return
    end

    error_if_invalid_url
    redirect_to analytics_path
  end

  private

  def populate_data_for_html
    @team = analytic_params[:team].presence
    @dates = available_report_dates
    @graphs = analytic_params.present? ? default_graphs : []
    @application_count = available_service_providers.count

    check_for_data_error
    error_if_invalid_url
  end

  def check_for_data_error
    if teams.blank? || available_service_providers.blank?
      @error = t('reports.errors.no_team')
    elsif identity_report.usage_data.empty? && identity_report.idv_data.empty?
      @error = t('reports.errors.no_data')
      @graphs = []
    end
  end

  def error_if_invalid_url
    return if analytic.valid? || analytic_params.blank?

    # Our preference is to use `flash.now` whenever possible,
    # but `flash.now` doesn't work immediately before a redirect.
    # Rubocop is unable to detect that this flash is getting set before a redirect
    # because setting the flash and the redirect happen in different methods.
    flash[:error] = analytic.errors.full_messages.join(' ') # rubocop:disable Rails/ActionControllerFlashBeforeRender
  end

  def analytic_params
    return params.permit(:team, :uuid, :date, :format) unless params[:analytic]

    params.require(:analytic).permit(:team, :uuid, :date)
  end

  def analytic
    return @analytic if @analytic

    @analytic = Analytic.new
    return @analytic unless current_user

    @analytic.config = service_provider
    @analytic.date = analytic_params[:date].presence || available_report_dates.first
    @analytic
  end

  def service_provider
    return available_service_providers.first unless analytic_params.present?

    policy_scope(ServiceProvider).find_by(
      uuid: analytic_params[:uuid],
    )
  end

  def teams
    @teams ||= current_user.scoped_teams.includes(:service_providers)
  end

  def all_app_options_string
    all_options = ''
    teams.each do |team|
      all_options += "#{app_options_string(team)},"
    end
    all_options
  end

  def available_service_providers
    @available_service_providers ||= policy_scope(ServiceProvider).where(
      issuer: AnalyticsReportStorage.new.all_issuers,
    )
  end

  def available_report_dates
    @available_report_dates ||= begin
      dates = Reports::Identity.available_dates(available_service_providers).uniq
      dates.presence || fallback_report_dates
    end
  end

  def fallback_report_dates
    current = Date.current.beginning_of_month
    dates = []
    while current >= EARLIEST_REPORT_DATE
      dates << current.strftime('%F')
      current = current.prev_month
    end
    dates
  end

  def identity_report
    @identity_report ||= Reports::Identity.new(analytic)
  end

  def default_graphs
    [
      {
        type: :column_chart,
        data: identity_report.usage_data,
        options: DEFAULT_GRAPH_OPTIONS,
      },
      {
        type: :column_chart,
        data: identity_report.idv_data,
        options: DEFAULT_GRAPH_OPTIONS,
      },
    ]
  end
end
