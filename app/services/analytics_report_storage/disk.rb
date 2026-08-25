class AnalyticsReportStorage
  # Pull analytics reports from a local folder on disk.
  class Disk
    attr_reader :service_config

    def self.default_config
      {
        root: IdentityConfig.store.local_reports_folder || Rails.root.join('spec/fixtures/reports'),
      }
    end

    def initialize(service_config = nil)
      @service_config = service_config || Disk.default_config
    end

    # @param key [String] the relative file path.
    # We use the relative file path here so that it looks just like
    # the arguments we also pass to S3. Example: '1234/monthly/2026-04-01.json'

    # @return [String] JSON data — may be '{}' if no data found
    def fetch(key)
      File.read(Pathname.new(root_path).join(key))
    rescue SystemCallError => err
      Rails.logger.warn(err.message)
      '{}'
    end

    private

    def root_path
      Pathname.new(service_config[:root])
    end
  end
end
