require 'rails_helper'

RSpec.describe ServiceProviderSerializer do
  subject(:serializer) { ServiceProviderSerializer.new(service_provider) }
  let(:fixture_path) { File.expand_path('../fixtures', __dir__) }
  let(:logo_filename) { 'logo.svg' }
  let(:team_agency_id) { SecureRandom.random_number(10_000) }
  let(:service_provider) do
    sp = create(:service_provider,
          redirect_uris: ['http://localhost:9292/result', 'x-example-app:/result'],
          updated_at: Time.zone.now,
          team: create(:team, agency: create(:agency, id: team_agency_id)),
          ial: 2,
          default_aal: 3,
          certs: [build_pem])
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
        expect(as_json[:remote_logo_key]).to eq(service_provider.logo_file.key)
        expect(as_json[:ial]).to eq(2)
        expect(as_json[:default_aal]).to eq(3)
        expect(as_json[:cert]).to eq(service_provider.certificates.first.to_pem)
      end
    end

    it 'gets the agency_id from the team' do
      expect(as_json[:agency_id]).to eq(team_agency_id)
    end
  end
end
