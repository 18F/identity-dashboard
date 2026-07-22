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

  def self.list_by_issuer(criteria = [])
    new.list_by_issuer(Array(criteria))
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

  # @param Array of Strings criteria to limit list results
  # @returns Array<Object> AWS object metadata
  def list(criteria)
    backend.list(issuer_to_id_map.values_at(*criteria).compact)
  end

  # @param Array<String> criteria to limit list results
  # @returns Hash<String,Array<Object>> [issuer, Array of file metadata objects]
  def list_by_issuer(criteria)
    # create a hash of issuer string => empty Array
    issuer_to_file_map = criteria.index_with { |_c| [] }
    # list files and associate with issuer in the above map
    list(criteria).each do |file|
      file_map_key = issuer_to_file_map[
        issuer_to_id_map.key(sp_identifier(file)),
      ]
      file_map_key&.push(file)
    end

    issuer_to_file_map
  end

  private

  def build_key(qualifier, date)
    "#{qualifier}/monthly/#{date}.json"
  end

  def use_s3?
    S3.default_config[:bucket] && S3.default_config[:prefix]
  end

  def fetch_id_map
    backend.fetch 'issuers_service_provider_id.json'
  end

  def issuer_to_id_map
    @issuer_to_id_map ||= Rails.cache.fetch('analytics_issuer_to_id_map', expires_in: 1.hour) do
      mapping_data = JSON.parse(fetch_id_map)
      if mapping_data.present?
        mapping_data.transform_values { |v| v['id'] }
      else
        {}
      end
    end
  end

  def sp_identifier(file)
    match = /(\d*)\/monthly\/.*\.json/.match(file.key)
    match && match[1].to_i
  end
end
