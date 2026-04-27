class AnalyticsReportCsv
  attr_reader :report_data

  def initialize(report_data)
    @report_data = report_data
  end

  def render_in(view_context)
    view_context.render body: report_data_csv
  end

  def format
    :csv
  end

  private

  def report_data_csv
    CSV.generate do |csv|
      csv << 'Test Data'
      csv << ['some data']
    end
  end
end
