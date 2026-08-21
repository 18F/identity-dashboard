require 'rails_helper'

RSpec.describe AnalyticsReportStorage::S3 do
  let(:s3_path) { 'test/portal' }
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
end
