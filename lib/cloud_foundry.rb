module CloudFoundry
  def self.raw_vcap_data
    ENV['VCAP_APPLICATION']
  end

  def self.vcap_data
    JSON.parse(raw_vcap_data) if cf_environment?
  end

  # returns `true` if this app is running in Cloud Foundry
  def self.cf_environment?
    raw_vcap_data.present?
  end

  def self.instance_index
    vcap_data['instance_index'] if cf_environment?
  end
end
