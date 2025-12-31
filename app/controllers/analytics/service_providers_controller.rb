class Analytics::ServiceProvidersController < ApplicationController # :nodoc:
  before_action -> { authorize User, policy_class: AnalyticsPolicy }

  # analytics/service/providers/{id}
  def show
    @issuer = service_provider.issuer
    @friendly_name = service_provider.friendly_name.capitalize
    @weekly_data = sp_weekly_data

    @recent_chart_data = @weekly_data.first(4)
  end

  private

  def service_provider
    @service_provider ||= ServiceProvider.includes(
      :agency,
      logo_file_attachment: :blob,
    ).find(id)
  end

  def id
    @id ||= params[:id]
  end

  def sp_weekly_data
    @sp_weekly_data ||=
      rows = sp_csv.select do |row|
        row['service_provider_issuer'] == service_provider.issuer
      end

    rows.map { |row| Analytics::Weekly.new(row.to_h) }
      .sort_by(&:date).reverse
  end

  def sp_csv
    @sp_csv ||= CSV.parse(
      File.read(Rails.root.join('spec', 'fixtures', 'files', 'weekly_sp_data.csv')),
      headers: true,
    )
  end
end
