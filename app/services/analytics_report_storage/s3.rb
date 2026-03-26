class AnalyticsReportStorage
  # Pull analytics reports from S3
  class S3
    attr_reader :service_config

    def initialize(service_config)
      @service_config = service_config
    end

    def list(criteria)
      s3_criteria = criteria
      s3_criteria = [''] if s3_criteria.blank?
      s3_criteria.flat_map do |criterion|
        s3_client.list_objects_v2(
          bucket: service_config[:bucket],
          prefix: "#{service_config[:prefix]}/#{criterion}",
        ).contents
      end
    end

    def fetch(key)
      s3_client.get_object(bucket: service_config[:bucket], key: key).body.read
    end

    private

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: service_config[:region])
    end
  end
end
