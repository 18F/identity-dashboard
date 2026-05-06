# Defines fetching reports from AWS S3 Buckets on production and local disk in development/test
class AnalyticsReportStorage
  ReportFile = Struct.new(:key, :file_size, :last_modified, keyword_init: true)

  attr_reader :backend, :issuer, :date

  delegate :list, to: :backend

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
                 AnalyticsReportStorage::Disk.new(disk_config)
               end
  end

  def fetch
    JSON.parse(backend.fetch(build_key(issuer, date)))
  end

  def time_interval
    build_key(issuer, date).split('/')[1]
  end

  private

  def build_key(qualifier, date)
    "#{qualifier}/monthly/#{date}.json"
  end

  def disk_config
    { root: IdentityConfig.store.local_reports_folder || Rails.root.join('spec/fixtures/reports') }
  end

  def use_s3?
    S3.default_config[:bucket] && S3.default_config[:prefix]
  end
end
