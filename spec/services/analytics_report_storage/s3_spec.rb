require 'rails_helper'

RSpec.describe AnalyticsReportStorage::S3 do
  let(:s3_path) { 'test/portal' }
  let(:mapping_object_path) { "#{s3_path}/issuer_service_provider_ids.json" }
  let(:data_object_path) { "#{s3_path}/monthly/2025-12-01 00:00:00.json" }
  let(:test_issuer) { "test:issuer:#{rand(10..1000)}" }
  let(:test_id) { rand(10.1000) }
  let(:client_with_stubs) do
    Aws::S3::Client.new(stub_responses: true)
  end

  before do
    allow(IdentityConfig.store).to receive(:aws_reports_path).and_return(s3_path)

    allow(Aws::S3::Client).to receive(:new).and_return(client_with_stubs)
  end

  describe '.all_issuers' do
    it 'returns a mapping when data present' do
      client_with_stubs.stub_responses(:list_objects_v2, contents: [
                                         { key: mapping_object_path },
                                         { key: data_object_path },
                                       ])
      client_with_stubs.stub_responses(:get_object,
          body: %({"#{test_issuer}":{"id":#{test_id}}}))
      expect(client_with_stubs).to receive(:get_object).with(
        bucket: IdentityConfig.store.aws_reports_bucket, key: mapping_object_path,
      ).and_call_original

      expect(described_class.new.all_issuers).to eq([test_issuer])
    end
  end

  describe '#list' do
    before do
      client_with_stubs.stub_responses(:list_objects_v2, contents: [
                                         { key: mapping_object_path },
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
  end
end
