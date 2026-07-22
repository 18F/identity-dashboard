require 'rails_helper'

RSpec.describe AnalyticsReportStorage do
  before { Rails.cache.clear }

  let(:test_issuer) { 'test:issuer' }
  let(:test_date) { '2025-12-01' }

  describe 'local disk storage' do
    let(:storage_root) { Rails.root.join('tmp/test_analytics_reports') }

    before(:all) do
      # Clear the cache once before starting this entire block of tests
      # since the tests use a different storage location
      Rails.cache.delete 'analytics_issuer_to_id_map'
    end

    before do
      FileUtils.mkdir_p(storage_root)
      allow(IdentityConfig.store).to receive(:local_reports_folder).and_return(storage_root)
    end

    after do
      FileUtils.rm_rf(storage_root)
      # Also clear the cache after each test in this block
      Rails.cache.delete 'analytics_issuer_to_id_map'
    end

    describe '.list' do
      before do
        expect(AnalyticsReportStorage::Disk).to receive(:default_config).and_return(
          { root: storage_root },
        )
      end

      context 'when directory is empty' do
        it 'returns an empty array' do
          expect(described_class.list).to eq([])
        end
      end

      context 'when directory has files' do
        let(:file1) { 'id1.json' }
        let(:file2) { 'id2.json' }
        let(:issuer1) { 'issuer1' }
        let(:issuer2) { 'issuer2' }

        before do
          File.write(storage_root.join(file1), '{}')
          File.write(storage_root.join(file2), '{}')
          File.write(
            storage_root.join('issuers_service_provider_id.json'),
            <<~JSON,
              {
                "issuer1": {"id": "#{file1}"},
                "issuer2": {"id": "#{file2}"}
              }
            JSON
          )
        end

        it 'returns file info for each file' do
          result = described_class.list([issuer1, issuer2])
          expect(result.length).to eq(2)
          expect(result.map(&:key)).to contain_exactly(file1.to_s, file2.to_s)
        end

        it 'includes file_size and last_modified' do
          result = described_class.list([issuer1]).first
          expect(result.file_size).to be_a(Integer)
          expect(result.last_modified).to be_a(Time)
        end
      end
    end

    describe '.fetch' do
      it 'returns parsed JSON content' do
        mock_data_location = File.join(file_fixture_path, '..', 'reports')
        allow(IdentityConfig.store).to receive(:local_reports_folder).and_return(
          mock_data_location,
        )

        real_issuer = 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test'
        result = described_class.fetch(real_issuer, test_date)

        expect(result['issuer']).to eq(real_issuer)
        expect(result['data'].keys.count).to eq(52)
      end

      it 'returns an empty result for a  non-existent file' do
        expect(described_class.fetch('fake', test_date)).to eq({})
      end
    end
  end

  describe 'S3 storage' do
    let(:s3_client_with_stubs) { Aws::S3::Client.new(stub_responses: true) }
    let(:bucket_name) { 'test-reports-bucket' }
    let(:bucket_prefix) { 'int/portal' }

    before(:all) do
      # Clear the cache once before starting this entire block of tests
      # since the tests use a different storage location
      Rails.cache.delete 'analytics_issuer_to_id_map'
    end

    before do
      allow(IdentityConfig.store).to receive_messages(
        aws_reports_bucket: bucket_name,
        aws_reports_path: bucket_prefix,
      )
      s3_client_with_stubs.stub_responses(:get_object, body: File.read(
        File.join(file_fixture_path, '..', 'reports', 'issuers_service_provider_id.json'),
      ))
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client_with_stubs)
    end

    after do
      # Also clear the cache after each test in this block

      Rails.cache.delete 'analytics_issuer_to_id_map'
    end

    describe '.list' do
      let(:s3_objects) do
        [
          double(key: 'report1.json', size: 1024, last_modified: Time.current),
          double(key: 'report2.json', size: 2048, last_modified: 1.day.ago),
        ]
      end

      before do
        allow(s3_client_with_stubs).to receive(:list_objects_v2)
          .with(bucket: bucket_name, prefix: "#{bucket_prefix}/")
          .and_return(double(contents: s3_objects))
      end

      it 'returns objects from S3 bucket' do
        result = described_class.list

        expect(result.map(&:key)).to contain_exactly('report1.json', 'report2.json')
      end

      it 'calls S3 with correct bucket' do
        described_class.list

        expect(s3_client_with_stubs).to have_received(:list_objects_v2).with(
          bucket: bucket_name, prefix: "#{bucket_prefix}/",
        ).at_least(:once)
      end
    end

    describe '.fetch' do
      context 'via S3' do
        let(:report_data) { [{ 'a_json_key' => 'a_json_value' }] }
        let(:s3_body) { double(read: report_data.to_json) }
        let(:test_issuer_id) { rand(1..1000) }
        let(:expected_s3_key) { "#{test_issuer_id}/monthly/#{test_date}.json" }

        before do
          allow(s3_client_with_stubs).to receive(:list_objects_v2).with(
            bucket: 'test-reports-bucket', prefix: 'int/portal/',
          ).and_return(double(
            contents: [
              AnalyticsReportStorage::Disk::ReportFile.new(key: 'issuers_service_provider_id.json'),
              AnalyticsReportStorage::Disk::ReportFile.new(key: expected_s3_key),
            ],
          ))
          allow(s3_client_with_stubs).to receive(:get_object).with(any_args) do |args|
            flunk(['Unexpected arguments', args])
          end
          allow(s3_client_with_stubs).to receive(:get_object)
            .with(bucket: bucket_name, key: 'int/portal/issuers_service_provider_id.json')
            .and_return(double(body: double(
              read: <<~JSON,
                {"#{test_issuer}": {"id": #{test_issuer_id}}}
              JSON
            )))
          allow(s3_client_with_stubs).to receive(:get_object)
            .with(bucket: bucket_name, key: "int/portal/#{expected_s3_key}")
            .and_return(double(body: s3_body))
        end

        it 'returns parsed JSON from S3' do
          result = described_class.fetch(test_issuer, test_date)

          expect(result).to eq(report_data)
        end

        it 'calls S3 only once with correct bucket and key' do
          described_class.fetch(test_issuer, test_date)

          expect(s3_client_with_stubs).to have_received(:get_object)
            .with(bucket: bucket_name, key: "int/portal/#{expected_s3_key}")
            .once
        end
      end
    end
  end

  describe '#issuer_to_id_map caching' do
    it 'fetches the mapping file once across multiple instances' do
      mock_backend = instance_double(AnalyticsReportStorage::Disk)
      allow(AnalyticsReportStorage::S3).to receive(:default_config).and_return({})
      allow(AnalyticsReportStorage::Disk).to receive(:new).and_return(mock_backend)
      # Clear the cache to ensure the new value of `fetch_id_map` gets used
      Rails.cache.delete 'analytics_issuer_to_id_map'
      allow(mock_backend).to receive(:fetch).with('issuers_service_provider_id.json')
        .and_return(%({"#{test_issuer}": {"id": 123}}))

      Rails.cache.clear
      described_class.new.all_issuers
      described_class.new.all_issuers

      expect(mock_backend).to have_received(:fetch).once

      # Since we populated the cache with `fetch_id_map`, we now have to clear the cache
      Rails.cache.delete 'analytics_issuer_to_id_map'
    end
  end

  describe '.all_issuers' do
    it 'returns a list when mapping data is present' do
      expect(AnalyticsReportStorage::S3).to receive(:default_config).and_return({})
      mock_backend = instance_double(AnalyticsReportStorage::Disk)
      expect(AnalyticsReportStorage::Disk).to receive(:new).and_return(mock_backend)
      expect(mock_backend).to receive(:fetch).with('issuers_service_provider_id.json')
        .and_return(%({"#{test_issuer}": {"id": 123}}))
      # Clear the cache to ensure the new value of `fetch_id_map` gets used
      Rails.cache.delete 'analytics_issuer_to_id_map'

      expect(described_class.new.all_issuers).to eq([test_issuer])

      # Since we populated the cache with `fetch_id_map`, we now have to clear the cache
      Rails.cache.delete 'analytics_issuer_to_id_map'
    end

    it 'returns an empty list when the mapping data is missing' do
      expect(AnalyticsReportStorage::S3).to receive(:default_config).and_return({})
      mock_backend = instance_double(AnalyticsReportStorage::Disk)
      expect(AnalyticsReportStorage::Disk).to receive(:new).and_return(mock_backend)
      expect(mock_backend).to receive(:fetch).with('issuers_service_provider_id.json').and_return('[]')
      expect(described_class.new.all_issuers).to eq([])
    end
  end
end
