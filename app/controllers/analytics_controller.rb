class AnalyticsController < ApplicationController # :nodoc:
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  # /reports
  def index
    teams = current_user.teams
    sps = teams.map(&:service_providers)
    @teams = teams.map do |team|
      [team.name, team.id]
    end
    @friendly_names = sps.to_a.flatten.map do |sp|
      [sp.friendly_name, sp.id]
    end
    @dates = %w[Today Tomorrow Yesterday]
    @graph_rows = []
    # two_column_options = { download: true, width: '30rem' }
    # @graph_rows.push([
    #                    { type: :line_chart, data: trends.active_users,
    #                      options: two_column_options },
    #                    { type: :line_chart, data: trends.active_applications,
    #                      options: two_column_options },
    #                  ])
    # @graph_rows.push([
    #                    { type: :line_chart, data: trends.active_applications,
    #                      options: two_column_options },
    #                    { type: :line_chart, data: trends.active_users,
    #                      options: two_column_options },
    #                  ])
    # @graph_rows.push([
    #                    { type: :area_chart, data: funnel.data, options: two_column_options },
    #                    { type: :bar_chart, data: funnel.dramatic_data,
    #                      options: two_column_options },
    #                  ])
    # @graph_rows.push([type: :bar_chart, data: funnel.stacked_data, options: {
    #   stacked: true, colors: ['#45472f', '#e895b3']
    # }])
    @report ||= Analytic.new
  end

  private

  def trends
    @trends ||= Reports::Trends.new(service_provider)
  end

  def funnel
    @funnel ||= Reports::AuthenticationFunnel.new(service_provider)
  end

  def id
    @id ||= params[:id]
  end
end
