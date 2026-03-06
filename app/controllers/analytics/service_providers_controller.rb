class Analytics::ServiceProvidersController < ApplicationController # :nodoc:
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  # analytics/service/providers/{id}
  def show
    @issuer = service_provider.issuer
    @friendly_name = service_provider.friendly_name.capitalize
    @available_reports = available_reports
    @selected_report = params[:report]
    @report_data = report_for_issuer(@issuer) if @selected_report.present?
  end

  private

  def available_reports
    AnalyticsReportStorage.list
      .select { |f| f.key.end_with?('.json') }
      .sort_by(&:last_modified)
      .reverse
  end

  def report_for_issuer(issuer)
    all_reports = AnalyticsReportStorage.fetch(@selected_report)
    
    all_reports.flatten.find { |report| 
    puts report['issuer']
    report['issuer'] == issuer }
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
