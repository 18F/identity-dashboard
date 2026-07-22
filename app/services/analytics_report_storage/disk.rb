class AnalyticsReportStorage
  # Pull analytics reports from a local folder on disk.
  class Disk
    attr_reader :service_config

    ReportFile = Struct.new(:key, :file_size, :last_modified, keyword_init: true)

    def self.default_config
      {
        root: IdentityConfig.store.local_reports_folder || Rails.root.join('spec/fixtures/reports'),
      }
    end

    def initialize(service_config = nil)
      @service_config = service_config || Disk.default_config
    end

    def list(criteria = ['/'])
      return [] unless root_path.exist?

      Dir.glob('**/*', base: root_path).filter_map do |filename|
        file = File.new(File.join(root_path, filename))

        next unless valid_file?(file)
        next unless criteria.any? { |criterion| filename.include?(criterion.to_s) }

        # Return the relative filename here so it can be passed back in to `#fetch`
        ReportFile.new(key: filename, file_size: file.size, last_modified: file.mtime)
      end
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

    def valid_file?(file_handle)
      # Skip directories
      return false if Dir.exist?(file_handle)

      file_handle.size.positive?
    end

    def root_path
      Pathname.new(service_config[:root])
    end
  end
end
