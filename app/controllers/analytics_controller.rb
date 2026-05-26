class AnalyticsController < ApplicationController # :nodoc:
  AVAILABLE_REPORTS = [Reports::Identity].freeze
  DEFAULT_GRAPH_OPTIONS = { download: true }.freeze
  EARLIEST_REPORT_DATE = Date.new(2025, 10, 1).freeze

  before_action -> { authorize analytic }
  after_action :verify_authorized
  after_action :verify_policy_scoped

  helper_method :teams_collection_for_select
  helper_method :service_providers_collection_for_select
  helper_method :selected_date_range

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
      redirect_to analytics_path(uuid: analytic.config.uuid, date: analytic.date) and return
    end

    error_if_invalid_url
    redirect_to analytics_path
  end

  private

  def populate_data_for_html
    @no_selections = teams_collection_for_select.blank? ||
                     service_providers_collection_for_select.blank?
    @dates = available_report_dates
    @graphs = default_graphs
    @application_count = available_service_providers.count

    error_if_invalid_url
  end

  def error_if_invalid_url
    return if analytic.valid? || analytic_params.blank?

    flash.now[:error] = analytic.errors.full_messages.join(' ')
  end

  def analytic_params
    return params.permit(:uuid, :date, :format) unless params[:analytic]

    params.require(:analytic).permit(:uuid, :date)
  end

  def analytic
    return @analytic if @analytic

    @analytic = Analytic.new
    return @analytic unless current_user

    @analytic.config = service_provider
    @analytic.date = analytic_params[:date].presence || available_report_dates.last
    @analytic
  end

  def service_provider
    return available_service_providers.first unless analytic_params.present?

    policy_scope(ServiceProvider).find_by(
      uuid: analytic_params[:uuid],
    )
  end

  def selected_date_range
    end_date = Date.parse(@analytic.date).end_of_month
    "#{@analytic.date} to #{end_date.strftime('%F')}"
  end

  def teams
    @teams ||= current_user.scoped_teams
  end

  def teams_collection_for_select
    teams.map do |team|
      [team.name, team.id]
    end
  end

  def service_providers_collection_for_select
    available_service_providers.to_a.flatten.map do |sp|
      [sp.friendly_name, sp.uuid]
    end
  end

  def available_service_providers
    @available_service_providers ||= begin
      available_issuers = policy_scope(ServiceProvider).pluck(:issuer).intersection(
        AnalyticsReportStorage.new.all_issuers,
      )
      policy_scope(ServiceProvider).where(
        team: teams,
        issuer: available_issuers,
      )
    end
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
