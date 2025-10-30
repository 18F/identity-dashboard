require 'rails_helper'
require './spec/support/migration_helpers'

SAMPLE_ISSUERS = [
  'howard:test',
  'hello_banana_fire_ball',
  '04:24:test:aj',
  'urn:gov:gsa:openidconnect.profiles:sp:sso:agency_name:05291148',
  '654756876587697863453242',
]

describe ServiceProviderArchiver do
  let(:sample_file) { File.join(file_fixture_path, 'extract_sample.json') }
  subject(:archiver) { described_class.new(sample_file) }
  let(:parsed_file) { JSON.parse(File.read(sample_file)) }

  context 'with a valid, portal-generated JSON file' do
    before do
      # These SPs must exist in order to take the Success happy path
      SAMPLE_ISSUERS.each do |issuer|
        create(:service_provider, :ready_to_activate, issuer:)
      end
    end

    it 'can inspect data and update status of valid configs' do
      expect { archiver.run }.to change {
        all_archived_configs.count
      }.by SAMPLE_ISSUERS.count
    end

    it 'is idempotent' do
      expect { archiver.run }.to change {
        all_archived_configs.count
      }.by SAMPLE_ISSUERS.count
      expect { archiver.run }.to_not change {
        all_archived_configs.count
      }
    end

    it 'correctly imports service_provider data from file' do
      archiver.run
      expect(JSON.parse(archiver.data.to_json)).to eq(parsed_file['service_providers'])
    end

    it 'returns no errors when file contains all valid data' do
      archiver.run
      expect(archiver.errors_any?).to be_falsy
    end

    it 'can do a dry run' do
      archiver.dry_run = true
      expect { archiver.run }.to_not change {
        all_archived_configs.count
      }
    end
  end

  context 'with a JSON file not matching existing issuers' do
    # No existing ServiceProviders

    it 'returns expected errors' do
      errors = archiver.run
      expect(archiver.errors_any?).to be_truthy
      SAMPLE_ISSUERS.each do |issuer|
        expect(errors[issuer].of_kind?(:issuer, :invalid)).to be_truthy
      end
    end

    it 'does not change anything' do
      expect { archiver.run }.to_not change { all_archived_configs.count }
    end
  end

  context 'with a JSON file that matches some issuers' do
    let(:some_issuers) { SAMPLE_ISSUERS[0..1] }
    let(:other_issuers) { SAMPLE_ISSUERS[2..] }

    before do
      some_issuers.each do |issuer|
        create(:service_provider, :ready_to_activate, issuer:)
      end
    end

    it 'returns errors and records valid issuers' do
      errors = archiver.run
      success_issuers = archiver.models.map { |m| m.issuer }
      failed_issuers = errors.keys

      expect(failed_issuers.count + success_issuers.count).to eq(SAMPLE_ISSUERS.count)
      expect(success_issuers).to eq(some_issuers)
      expect(failed_issuers).to eq(other_issuers)
    end

    it 'returns expected errors' do
      errors = archiver.run
      expect(archiver.errors_any?).to be_truthy
      other_issuers.each do |issuer|
        expect(errors[issuer].of_kind?(:issuer, :invalid)).to be_truthy
      end
    end

    it 'does not update valid SPs when errors are found' do
      expect { archiver.run }.to_not change {
        all_archived_configs.count
      }
    end
  end
end
