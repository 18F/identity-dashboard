class AnalyticsController < ApplicationController # :nodoc:
  AVAILABLE_REPORTS = [Reports::Identity].freeze
  DEFAULT_GRAPH_OPTIONS = { download: true }.freeze
  TEMP_HARDCODED_ISSUER_FOR_MVP = 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb'.freeze

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
    @teams ||= current_user.teams
  end

  def temporary_hardcoded_scope_for_testing_mvp(scope)
    scope.where(issuer: TEMP_HARDCODED_ISSUER_FOR_MVP)
  end

  def sps
    @sps ||= policy_scope(
      temporary_hardcoded_scope_for_testing_mvp(ServiceProvider),
    ).where(team: teams)
  end

  def available_report_dates
    Reports::Identity.available_dates(sps)
  end

  def identity_report
    @identity_report ||= Reports::Identity.new(analytic)
  end

  def analytic
    return Analytic.new unless current_user

    @analytic ||= Analytic.new(config: sps.first, date: available_report_dates.last)
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
      # {
      #   type: :bar_chart,
      #   data: identity_report.fraud_data,
      #   options: DEFAULT_GRAPH_OPTIONS.merge(
      #     title: 'Fraud Prevention',
      #     xtitle: 'Users blocked per outcome type',
      #   ),
      # },
      # {
      #   type: :bar_chart,
      #   data: identity_report.fraud_redress,
      #   options: DEFAULT_GRAPH_OPTIONS.merge(
      #     title: 'Fraud Review Activity',
      #     xtitle: '"Adjudicated as legitimate" reflects cases where Login.gov reviewed the case '\
      #             'and reversed the block.',
      #   ),
      # },
      # {
      #   type: :bar_chart,
      #   data: identity_report.mfa_data,
      #   options: DEFAULT_GRAPH_OPTIONS.merge(title: 'Authentication by MFA Type'),
      # },
    ]
  end
end
