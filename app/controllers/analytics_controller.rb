class AnalyticsController < ApplicationController # :nodoc:
  AVAILABLE_REPORTS = [Reports::Identity].freeze
  DEFAULT_GRAPH_OPTIONS = { download: true }.freeze
  EARLIEST_REPORT_DATE = Date.new(2025, 10, 1).freeze

  before_action -> { authorize analytic }
  after_action :verify_authorized
  after_action :verify_policy_scoped

  helper_method :teams_collection_for_select
  helper_method :service_providers_collection_for_select

  # /reports
  def show
    respond_to do |format|
      format.html do
        populate_data_for_html
      end
      format.csv do
        report = AnalyticsReportCsv.new(identity_report)
        send_data report.report_data_csv, filename: report.filename
      end
    end
  end

  private

  def populate_data_for_html
    @no_reports = teams_collection_for_select.blank? ||
                  service_providers_collection_for_select.blank?
    @dates = available_report_dates
    @graphs = default_graphs
    @application_count = sps.count
  end

  def analytic_params
    return {} unless params[:analytic]

    params.require(:analytic).permit(:service_provider_id, :date)
  end

  def analytic
    return Analytic.new unless current_user

    if analytic_params.present?
      @analytic = Analytic.new(
        config: service_provider,
        date: analytic_params[:date],
      )
    end

    @analytic ||= Analytic.new(config: sps.first,
                               date: available_report_dates.last)
  end

  def selected_date
    analytic_params[:date].presence
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
    sps.to_a.flatten.map do |sp|
      [sp.friendly_name, sp.id]
    end
  end

  def service_provider
    return sps.first unless analytic_params.present?

    ServiceProvider.find analytic_params[:service_provider_id]
  end

  def sps
    available_issuers = ServiceProvider.pluck(:issuer).intersection(
      AnalyticsReportStorage.new.all_issuers,
    )
    @sps ||= policy_scope(ServiceProvider).where(
      team: teams,
      issuer: available_issuers,
    )
  end

  def available_report_dates
    dates = Reports::Identity.available_dates([service_provider])
    return dates if dates.present?

    fallback_report_dates
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

  def id
    @id ||= params[:id]
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
