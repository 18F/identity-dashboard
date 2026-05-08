class AnalyticsReportStorage
  # Pull analytics reports from S3
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

    def all_issuers
      issuer_to_id_map.keys
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

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: service_config[:region])
    end
  end

  private

  def issuer_to_id_map
    @issuer_to_id_map ||= begin
      # We'll probably want more aggresive caching of and parsing this map for performance reasons.
      # Caching should be easy here since we don't expect it to change more than daily.
      mapping_object = list([]).find do |object|
        object.key.include?("#{service_config[:prefix]}/issuer")
      end
      JSON.parse(fetch(mapping_object.key)).transform_values do |v|
        v['id']
      end
    end
  end
end
