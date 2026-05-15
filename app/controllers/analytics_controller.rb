class AnalyticsController < ApplicationController # :nodoc:
  AVAILABLE_REPORTS = [Reports::Identity].freeze
  DEFAULT_GRAPH_OPTIONS = { download: true }.freeze

  before_action -> { authorize analytic }
  after_action :verify_authorized
  after_action :verify_policy_scoped

  # /reports
  def index
    @teams_collection = teams.map do |team|
      [team.name, team.id]
    end
    @friendly_names = sps.to_a.flatten.map do |sp|
      [sp.friendly_name, sp.id]
    end
    @dates = available_report_dates
    @graphs = default_graphs
    @application_count = AnalyticsReportStorage.new.all_issuers.count
  end

  # /reports/download
  def download
    report = AnalyticsReportCsv.new(identity_report)
    send_data report.report_data_csv, filename: report.filename
  end

  private

  def teams
    @teams ||= current_user.scoped_teams
  end

  def sps
    # TODO: remove .reverse once we account for missing SP data
    @sps ||= policy_scope(ServiceProvider.all).reverse
  end

  def available_report_dates
    Reports::Identity.available_dates(sps)
  end

  def identity_report
    @identity_report ||= Reports::Identity.new(analytic)
  end

  def analytic
    return Analytic.new unless current_user

    @analytic ||= Analytic.new(config: sps.first, date: available_report_dates.first)
  end

  def id
    @id ||= params[:id]
  end

  def default_graphs
    [
      {
        type: :column_chart,
        data: identity_report.usage_data,
        options: DEFAULT_GRAPH_OPTIONS.merge(title: 'Active Users'),
      },
      {
        type: :column_chart,
        data: identity_report.idv_data,
        options: DEFAULT_GRAPH_OPTIONS.merge(title: 'Identity Verified Users'),
      },
    ]
  end
end
