class AnalyticsReportStorage
  def self.list
    new.list
  end

  def self.fetch(key)
    new.fetch(key)
  end

  def list
    disk_storage? ? list_local : list_s3
  end

  def fetch(key)
    content = disk_storage? ? fetch_local(key) : fetch_s3(key)
    JSON.parse(content)
  end

  private

  def disk_storage?
    service_config[:service] == 'Disk'
  end

  def service_name
    Rails.env.production? ? :reports_amazon : :reports_local
  end

  def service_config
    Rails.configuration.active_storage.service_configurations[service_name.to_s].symbolize_keys
  end

  def list_local
    root = Pathname.new(service_config[:root])
    return [] unless root.exist?

    root.children.map do |file|
      OpenStruct.new(key: file.basename.to_s, size: file.size, last_modified: file.mtime)
    end
  end

  def list_s3
    s3_client.list_objects_v2(bucket: service_config[:bucket]).contents
  end

  def fetch_local(key)
    File.read(Pathname.new(service_config[:root]).join(key))
  end

  def fetch_s3(key)
    s3_client.get_object(bucket: service_config[:bucket], key: key).body.read
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: service_config[:region])
  end
end
