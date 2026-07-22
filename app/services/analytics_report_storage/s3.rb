class AnalyticsReportStorage
  # Pull analytics reports from S3
  # This class does not know about the mapping between the issuer string and the issuer ID,
  class S3
    attr_reader :service_config

    # can this be a constant?
    def self.default_config
      { bucket: IdentityConfig.store.aws_reports_bucket,
        prefix: IdentityConfig.store.aws_reports_path,
        region: IdentityConfig.store.aws_region }
    end

    def initialize(service_config = nil)
      @service_config = service_config || S3.default_config
    end

    def list(criteria)
      s3_criteria = criteria
      s3_criteria = [''] if s3_criteria.blank?
      s3_criteria.flat_map do |criterion|
        # returns metadata of files: etag, key, last_modified, size, storage_class
        s3_client.list_objects_v2(
          bucket: service_config[:bucket],
          prefix: "#{service_config[:prefix]}/#{criterion}",
        ).contents
      end
    rescue Aws::S3::Errors::NoSuchKey
      []
    end

    # @param key [String] example: '1234/monthly/2026-04-01.json'
    def fetch(key)
      s3_client.get_object(
        bucket: service_config[:bucket],
        key: "#{service_config[:prefix]}/#{key}",
      ).body.read
    rescue Aws::S3::Errors::NoSuchKey
      '{}'
    end

    private

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: service_config[:region])
    end
  end
end
