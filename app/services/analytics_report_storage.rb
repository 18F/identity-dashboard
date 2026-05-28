# Defines fetching reports from AWS S3 Buckets on production and local disk in development/test
#
# This class abstracts away having to map between the issuer string and the
# issuer/service_provider ID. You should give this class the issuer string, and it will try to find
# a mapping file to look up the corresponding IDs.
# It will then use the IDs to tell the backend (S3 or Disk) which filename to fetch.
class AnalyticsReportStorage
  attr_reader :backend, :issuer, :date

  def self.list(criteria = [])
    new.list(Array(criteria))
  end

  def self.fetch(issuer, date)
    new(issuer, date).fetch
  end

  def initialize(issuer = nil, date = nil)
    (@issuer, @date) = issuer, date
    @backend = if use_s3?
                 AnalyticsReportStorage::S3.new
               else
                 AnalyticsReportStorage::Disk.new
               end
  end

  def fetch
    JSON.parse(backend.fetch(build_key(issuer_to_id_map[issuer], date)))
  end

  def time_interval
    build_key(issuer, date).split('/')[1]
  end

  def all_issuers
    issuer_to_id_map.keys
  end

  def list(criteria)
    begin
      backend.list(issuer_to_id_map.values_at(*criteria).compact)
    rescue Aws::S3::Errors::NoSuchKey
      []
    end
  end

  private

  def build_key(qualifier, date)
    "#{qualifier}/monthly/#{date}.json"
  end

  def use_s3?
    S3.default_config[:bucket] && S3.default_config[:prefix]
  end

  def issuer_to_id_map
    @issuer_to_id_map ||= Rails.cache.fetch('analytics_issuer_to_id_map', expires_in: 1.hour) do
      mapping_data = JSON.parse(backend.fetch_id_map)
      if mapping_data.present?
        mapping_data.transform_values { |v| v['id'] }
      else
        {}
      end
    end
  end
end
