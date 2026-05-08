class AnalyticsReportStorage
  ReportFile = Struct.new(:key, :file_size, :last_modified, keyword_init: true) do
    def issuer_id
      match = /(.*)\/monthly\/.*\.json/.match(key)
      match && match[1]
    end
  end
end
