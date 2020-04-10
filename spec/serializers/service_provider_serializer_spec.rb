require 'rails_helper'

RSpec.describe ServiceProviderSerializer do
  subject(:serializer) { ServiceProviderSerializer.new(service_provider) }
  let(:fixture_path) { File.expand_path('../fixtures', __dir__) }
  let(:logo_filename) { 'logo.svg' }
  let(:service_provider) do
    sp = create(:service_provider,
          redirect_uris: ['http://localhost:9292/result', 'x-example-app:/result'],
          updated_at: Time.zone.now)
    sp.logo_file.attach(io: File.open(fixture_path + "/#{logo_filename}"), filename: logo_filename)
    sp.update(logo: logo_filename)
    sp.reload
  end

  describe '#as_json' do
    subject(:as_json) { serializer.as_json }

    it 'serializes attributes' do
      aggregate_failures do
        expect(as_json[:issuer]).to eq(service_provider.issuer)
        expect(as_json[:redirect_uris]).to eq(service_provider.redirect_uris)
        expect(as_json[:logo]).to eq('logo.svg')
        expect(as_json[:logo_key]).to eq(service_provider.logo_file.key)
      end
    end
  end
end
