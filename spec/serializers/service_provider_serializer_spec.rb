require 'rails_helper'

RSpec.describe ServiceProviderSerializer do
  subject(:serializer) { ServiceProviderSerializer.new(service_provider) }
  let(:service_provider) do
    build(:service_provider,
          redirect_uris: ['http://localhost:9292/result', 'x-example-app:/result'],
          updated_at: Time.zone.now)
  end

  describe '#as_json' do
    subject(:as_json) { serializer.as_json }

    it 'serializes attributes' do
      aggregate_failures do
        expect(as_json[:issuer]).to eq(service_provider.issuer)
        expect(as_json[:redirect_uris]).to eq(service_provider.redirect_uris)
      end
    end

    it 'is backwards compatible with (singular) redirect_uri' do
      expect(as_json[:redirect_uri]).to eq(service_provider.redirect_uris.first)
    end
  end
end
