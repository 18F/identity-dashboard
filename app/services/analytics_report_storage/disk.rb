class AnalyticsReportStorage
  # Pull analytics reports from a local folder on disk.
  class Disk
    attr_reader :service_config

    def initialize(service_config)
      @service_config = service_config
    end

    def list(criteria = [])
      root = Pathname.new(path)
      return [] unless root.exist?

      Dir.glob("#{root}/**/*").filter_map do |filename|
        # Skip directories
        next if Dir.exist? filename
        next unless criteria.any? { |criterion| filename.include?(criterion) }

        file = File.new(filename)

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
