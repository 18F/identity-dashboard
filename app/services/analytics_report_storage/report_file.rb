class AnalyticsReportStorage
  ReportFile = Struct.new(:key, :file_size, :last_modified, keyword_init: true) do
    def issuer
      match = /(.*)\/monthly\/.*\.json/.match(key)
      match.present? && match[0]
    end
  end
end
