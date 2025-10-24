require 'rails_helper'

SAMPLE_ISSUERS = [
"howard:test",
"hello_banana_fire_ball",
"04:24:test:aj",
"urn:gov:gsa:openidconnect.profiles:sp:sso:agency_name:05291148",
"654756876587697863453242",
]

describe ServiceProviderDisabler do
  let(:good_file) { File.join(file_fixture_path, 'extract_sample.json') }

  context 'with a valid JSON file' do
    subject(:disabler) { described_class.new(good_file) }
    let(:parsed_file) { JSON.parse(File.read(good_file)) }

    before do
      # These SPs must exist in order to take the Success happy path
      SAMPLE_ISSUERS.each do |issuer|
        create(:service_provider, :ready_to_activate, issuer:)
      end
    end

    it 'can inspect data and update status of valid configs' do
      expect { disabler.run }.to change {
      (ServiceProvider.where(issuer: SAMPLE_ISSUERS).filter { |sp|
        sp.status == 'moved_to_prod'
      }).count }.by SAMPLE_ISSUERS.count
    end

    it 'is idempotent' do
      expect { disabler.run }.to change {
      (ServiceProvider.where(issuer: SAMPLE_ISSUERS).filter { |sp|
        sp.status == 'moved_to_prod'
      }).count }.by SAMPLE_ISSUERS.count
      expect { disabler.run }.to_not change {
      (ServiceProvider.where(issuer: SAMPLE_ISSUERS).filter { |sp|
        sp.status == 'moved_to_prod'
      }).count }
    end

    it 'correctly imports service_provider data from file' do
      disabler.run
      expect(JSON.parse(disabler.data.to_json)).to eq(parsed_file['service_providers'])
    end

    it 'returns no errors when file contains all valid data' do
      disabler.run
      expect(disabler.errors_any?).to be_falsy
    end
  end
end
