require 'rails_helper'

RSpec.describe AnalyticsReportStorage do
  describe 'local disk storage' do
    let(:storage_root) { Rails.root.join('tmp/test_analytics_reports') }

    before do
      FileUtils.mkdir_p(storage_root)
      allow(Rails.configuration.active_storage).to receive(:service_configurations).and_return(
        'reports_local' => {
          'service' => 'Disk',
          'root' => storage_root.to_s,
        },
      )
    end

    after do
      FileUtils.rm_rf(storage_root)
    end

    describe '.list' do
      context 'when directory is empty' do
        it 'returns an empty array' do
          expect(described_class.list).to eq([])
        end
      end

      context 'when directory has files' do
        before do
          File.write(storage_root.join('report1.json'), '{}')
          File.write(storage_root.join('report2.json'), '{}')
        end

        it 'returns file info for each file' do
          result = described_class.list

          expect(result.length).to eq(2)
          expect(result.map(&:key)).to contain_exactly('report1.json', 'report2.json')
        end

        it 'includes file_size and last_modified' do
          result = described_class.list.first

          expect(result.file_size).to be_a(Integer)
          expect(result.last_modified).to be_a(Time)
        end
      end
    end

    describe '.fetch' do
      let(:report_data) do
        [
          [{ 'issuer' => 'test:issuer', 'count_users' => '100' }],
        ]
      end

      before do
        File.write(storage_root.join('report.json'), report_data.to_json)
      end

      it 'returns parsed JSON content' do
        result = described_class.fetch('report.json')

        expect(result).to eq(report_data)
      end

      it 'raises error for non-existent file' do
        expect { described_class.fetch('missing.json') }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe 'S3 storage' do
    let(:s3_client) { instance_double(Aws::S3::Client) }
    let(:bucket_name) { 'test-reports-bucket' }

    before do
      allow(Rails.configuration.active_storage).to receive(:service_configurations).and_return(
        'reports_local' => {
          'service' => 'S3',
          'region' => 'us-west-2',
          'bucket' => bucket_name,
        },
      )
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
    end

    describe '.list' do
      let(:s3_objects) do
        [
          double(key: 'report1.json', size: 1024, last_modified: Time.current),
          double(key: 'report2.json', size: 2048, last_modified: 1.day.ago),
        ]
      end

      before do
        allow(s3_client).to receive(:list_objects_v2)
          .with(bucket: bucket_name)
          .and_return(double(contents: s3_objects))
      end

      it 'returns objects from S3 bucket' do
        result = described_class.list

        expect(result.map(&:key)).to contain_exactly('report1.json', 'report2.json')
      end

      it 'calls S3 with correct bucket' do
        described_class.list

        expect(s3_client).to have_received(:list_objects_v2).with(bucket: bucket_name)
      end
    end

    describe '.fetch' do
      let(:report_data) { [{ 'issuer' => 'test:issuer' }] }
      let(:s3_body) { double(read: report_data.to_json) }

      before do
        allow(s3_client).to receive(:get_object)
          .with(bucket: bucket_name, key: 'report.json')
          .and_return(double(body: s3_body))
      end

      it 'returns parsed JSON from S3' do
        result = described_class.fetch('report.json')

        expect(result).to eq(report_data)
      end

      it 'calls S3 with correct bucket and key' do
        described_class.fetch('report.json')

        expect(s3_client).to have_received(:get_object).with(bucket: bucket_name,
                                                             key: 'report.json')
      end
    end
  end
end
