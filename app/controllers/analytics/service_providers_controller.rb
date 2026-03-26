class Analytics::ServiceProvidersController < ApplicationController # :nodoc:
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  # analytics/service/providers/{id}
  def show
    @issuer = service_provider.issuer
    @friendly_name = service_provider.friendly_name.capitalize
    @graph_rows = []

    two_column_options = { download: true, width: '30rem',
                           options: {
                             plugins: {
                               a11y_legend: {
                                 margin: 0,
                               },
                             },
                           } }
    @graph_rows.push([
                       { type: :line_chart, data: trends.active_users,
                         options: two_column_options },
                       { type: :line_chart, data: trends.active_applications,
                         options: two_column_options },
                     ])
    @graph_rows.push([
                       { type: :line_chart, data: trends.active_applications,
                         options: two_column_options },
                       { type: :line_chart, data: trends.active_users,
                         options: two_column_options },
                     ])
    @graph_rows.push([
                       { type: :area_chart, data: funnel.data, options: two_column_options },
                       { type: :bar_chart, data: funnel.dramatic_data,
                         options: two_column_options },
                     ])
    @graph_rows.push([type: :bar_chart, data: funnel.stacked_data, options: {
      stacked: true, colors: ['#45472f', '#e895b3']
    }])
  end

  private

  def trends
    @trends ||= Reports::Trends.new(service_provider)
  end

  def funnel
    @funnel ||= Reports::AuthenticationFunnel.new(service_provider)
  end

  def service_provider
    @service_provider ||= ServiceProvider.includes(
      :agency,
      logo_file_attachment: :blob,
    ).find(id)
  end

  def id
    @id ||= params[:id]
  end
end
