require 'rails_helper'

SAMPLE_ISSUERS = [
  "urn:gov:gsa:openidconnect.profiles:sp:sso:gsa:sandbox-test",
  "urn:gov:gsa:openidconnect.profiles:sp:sso:agency_name:help_text",
  "2024-10-15:non-admin:test",
  "2024-10-17:helptext",
  "2024-11-06-mobile-test",
  "asdfsadfasd",
  "asdfsadfas",
  "2025-01-13:fields:test",
  "2024-01-09:saml:test",
  "2024-10-18-helptext",
]

describe ServiceProviderDisabler do
  let(:good_file) { File.join(file_fixture_path, 'extract_sample.json') }

  context 'with a valid JSON file' do
    subject(:disabler) { described_class.new(good_file) }

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
      }).count }.by 10
      expect { disabler.run }.to_not change {
      (ServiceProvider.where(issuer: SAMPLE_ISSUERS).filter { |sp|
        sp.status == 'moved_to_prod'
      }).count }
    end

    it 'correctly imports data from file' do
      disabler.run
      expect(disabler.data.to_json).to eq(File.read(good_file))
    end

    it 'returns no errors when file contains all valid data' do
      disabler.run
      expect(disabler.errors_any?).to be_falsy
    end
  end
end
