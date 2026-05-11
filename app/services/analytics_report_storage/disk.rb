class AnalyticsReportStorage
  # Pull analytics reports from a local folder on disk.
  class Disk
    attr_reader :service_config

    def self.default_config
      { root: IdentityConfig.store.local_reports_folder || Rails.root.join('spec/fixtures/reports') }
    end

    def initialize(service_config = nil)
      @service_config = service_config || Disk.default_config
    end

    def list(criteria = ['/'])
      root = Pathname.new(path)
      return [] unless root.exist?

      Dir.glob('**/*', base: root).filter_map do |filename|
        fully_qualified_filename = File.join(root, filename)
        # Skip directories
        next if Dir.exist?(fully_qualified_filename)
        next unless criteria.any? { |criterion| filename.include?(criterion.to_s) }

        file = File.new(fully_qualified_filename)

        next unless file.size.positive?

        ReportFile.new(key: filename, file_size: file.size, last_modified: file.mtime)
      end
    end

    def all_issuers
      list(['/']).filter_map(&:sp_identifier).uniq
    end

    # @return [String] JSON data — may be '[]' if no data found
    def fetch(key)
      File.read(Pathname.new(path).join(key))
    rescue SystemCallError => err
      Rails.logger.warn(err.message)
      '[]'
    end

    private

    def path
      service_config[:root]
    end
  end
end
