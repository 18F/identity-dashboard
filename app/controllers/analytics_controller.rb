class AnalyticsController < ApplicationController # :nodoc:
  AVAILABLE_REPORTS = [Reports::Identity].freeze
  DEFAULT_GRAPH_OPTIONS = { download: true }.freeze
  EARLIEST_REPORT_DATE = Date.new(2025, 10, 1).freeze

  before_action -> { authorize analytic }
  before_action :validate_and_compile_errors
  after_action :verify_authorized
  after_action :verify_policy_scoped

  # /reports
  def index
    respond_to do |format|
      format.html do
        populate_data_for_html
        flash[:error] = I18n.t('reports.errors.no_team') if @application_count.zero?
      end
      format.csv do
        report = AnalyticsReportCsv.new(identity_report)
        send_data report.report_data_csv, filename: report.filename
      end
    end
  end

  def fetch
    # TODO: This needs to change to disable or remove the View report button
    return redirect_to analytics_path unless analytic.config

    redirect_to analytics_path(team: analytic.config.team,
                               uuid: analytic.config.uuid,
                               date: analytic.date) and return
  end

  private

  def populate_data_for_html
    @teams = permitted_teams
    @team = analytic_params[:team].presence
    @dates = available_report_dates
    @graphs = analytic_params.present? ? default_graphs : []
    @application_count = available_service_providers.count
  end

  def validate_and_compile_errors
    return if analytic.valid? || analytic_params.blank?

    @error = analytic.errors.full_messages.join(' ')
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
    @analytic.data = identity_report.data
    @analytic
  end

  def service_provider
    return available_service_providers.first unless analytic_params.present?

    policy_scope(ServiceProvider).find_by(
      uuid: analytic_params[:uuid],
    )
  end

  def permitted_teams
    teams = current_user.scoped_teams.filter do |team|
      team.service_providers.present?
    end
    return teams if current_user.logingov_staff?

    current_user.team_memberships.where(
      role: 'partner_admin',
      team: [teams],
    ).map(&:team)
  end

  def available_service_providers
    return @available_service_providers if @available_service_providers

    service_providers ||= policy_scope(ServiceProvider).where(
      issuer: AnalyticsReportStorage.new.all_issuers,
    )
    @available_service_providers = service_providers.where(team: permitted_teams)
  end

  def available_report_dates
    @available_report_dates ||= begin
      dates = Reports::Identity.available_dates(available_service_providers, current_user)
      dates.values.flatten.uniq.presence || fallback_report_dates
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
        title: 'All Active Users',
        options: DEFAULT_GRAPH_OPTIONS.merge({
          subtitle: 'Unique users who accessed a service',
          description: 'New accounts reflect account creation during this window. ' \
            'Existing accounts reflect accounts created ahead of this window.',
        }),
      },
      {
        type: :column_chart,
        data: identity_report.idv_data,
        title: 'Active Identity Verified Users',
        options: DEFAULT_GRAPH_OPTIONS.merge({
          subtitle: 'Unique users who accessed a service requiring verification',
          description: 'Newly proofed are net new users who verified during this window. ' \
            'Previously proofed are users who completed verification ahead of this window,',
        }),
      },
    ]
  end
end
