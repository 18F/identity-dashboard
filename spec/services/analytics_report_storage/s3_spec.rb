require 'rails_helper'

RSpec.describe AnalyticsReportStorage::S3 do
  let(:s3_path) { 'test/portal' }
  let(:data_object_path) { "#{s3_path}/monthly/2025-12-01.json" }
  let(:test_issuer) { "test:issuer:#{rand(10..1000)}" }
  let(:test_id) { rand(10..1000) }
  let(:client_with_stubs) do
    Aws::S3::Client.new(stub_responses: true)
  end
  let(:s3_nosuchkey_error) do
    Aws::S3::Errors::NoSuchKey.new('key', 'The specified key does not exist.')
  end

  before do
    allow(IdentityConfig.store).to receive(:aws_reports_path).and_return(s3_path)

    allow(Aws::S3::Client).to receive(:new).and_return(client_with_stubs)
  end

  describe '#list' do
    before do
      client_with_stubs.stub_responses(:list_objects_v2, contents: [
                                         { key: data_object_path },
                                       ])
    end

    it 'calls s3 with the expected criteria' do
      test_key = "issuer:#{rand(10..1000)}/monthly"
      expect(client_with_stubs).to receive(:list_objects_v2).with(
        bucket: IdentityConfig.store.aws_reports_bucket, prefix: "#{s3_path}/#{test_key}",
      ).and_call_original
      described_class.new.list([test_key])
    end

    it 'calls s3 with the default criteria if the criteria are blank' do
      expect(client_with_stubs).to receive(:list_objects_v2).with(
        bucket: IdentityConfig.store.aws_reports_bucket, prefix: "#{s3_path}/",
      ).and_call_original
      described_class.new.list([])
    end

    describe 'error' do
      before do
        allow(Aws::S3::Client).to receive(:new).and_raise(s3_nosuchkey_error)
      end

      it 'handles missing data files' do
        result = described_class.new.list(["random_key#{rand(10..1000)}"])

        expect(result).to eq([])
      end
    end
  end

  describe '#fetch' do
    it 'calls S3 based on the config options' do
      # described_class#list returns data that includes the prefix already
      # so #fetch will accept those keys without needing or applying further formatting
      test_key = "random_key#{rand(10..1000)}"

      expect(client_with_stubs).to receive(:get_object).with(
        bucket: described_class.default_config[:bucket],
        key: "#{described_class.default_config[:prefix]}/#{test_key}",
      ).and_call_original

      described_class.new.fetch(test_key)
    end

    describe 'error' do
      before do
        allow(Aws::S3::Client).to receive(:new).and_raise(s3_nosuchkey_error)
      end

      it 'handles missing data files' do
        result = described_class.new.fetch("random_key#{rand(10..1000)}")

        expect(result).to eq('{}')
      end
    end
  end

  describe '#fetch_id_map' do
    it 'calls S3 to get the expected file' do
      expected_text = Rails.root.join(
        'spec/fixtures/reports/issuers_service_provider_id.json',
      ).read
      expect(client_with_stubs).to receive(:get_object).with(
        bucket: described_class.default_config[:bucket],
        key: "#{described_class.default_config[:prefix]}/issuers_service_provider_id.json",
      ).and_call_original
      client_with_stubs.stub_responses(:get_object, body: expected_text)

      expect(described_class.new.fetch_id_map).to eq(expected_text)
    end
  end
end
