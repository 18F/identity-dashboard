class AnalyticsController < ApplicationController # :nodoc:
  AVAILABLE_REPORTS = [Reports::Identity].freeze
  DEFAULT_GRAPH_OPTIONS = { download: true }.freeze
  TEMP_HARDCODED_ISSUER_FOR_MVP = 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb'.freeze

  before_action -> { authorize analytic }
  after_action :verify_authorized
  after_action :verify_policy_scoped,
  # /reports
  def index
    @teams_collection = teams.map do |team|
      [team.name, team.id]
    end
    @friendly_names = sps.to_a.flatten.map do |sp|
      [sp.friendly_name, sp.id]
    end
    @dates = available_report_dates

    @graphs = [
      {
        type: :bar_chart,
        data: identity_report.fraud_data,
        options: DEFAULT_GRAPH_OPTIONS.merge(title: 'Fraud Counts'),
      },
      {
        type: :bar_chart,
        data: identity_report.data_other,
        options: DEFAULT_GRAPH_OPTIONS.merge(title: 'Other Interactions'),
      },
    ]
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
    Reports::Identity.new(analytic)
  end

  def analytic
    return Analytic.new unless current_user

    @analytic ||= Analytic.new(config: sps.first, date: available_report_dates.last)
  end

  def id
    @id ||= params[:id]
  end
end
