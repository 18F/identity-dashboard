# Defines fetching reports from AWS S3 Buckets on production and local disk in development/test
class AnalyticsReportStorage
  ReportFile = Struct.new(:key, :file_size, :last_modified, keyword_init: true)

  attr_reader :backend

  delegate :list, to: :backend

  def self.list(criteria = [])
    new.list(Array(criteria))
  end

  def self.fetch(issuer, date)
    new.fetch(issuer, date)
  end

  def initialize
    @backend = if use_s3?
                 AnalyticsReportStorage::S3.new(s3_config)
               else
                 AnalyticsReportStorage::Disk.new(disk_config)
               end
  end

  def fetch(issuer, date)
    JSON.parse(backend.fetch(build_key(issuer, date)))
  end

  private

  def build_key(qualifier, date)
    "#{qualifier}/monthly/#{date}.json"
  end

  def s3_config
    {
      bucket: IdentityConfig.store.aws_reports_bucket,
      prefix: IdentityConfig.store.aws_reports_path,
    }
  end

  def disk_config
    { root: IdentityConfig.store.local_reports_folder || Rails.root.join('spec/fixtures/reports') }
  end

  def use_s3?
    s3_config[:bucket] && s3_config[:prefix]
  end
end
