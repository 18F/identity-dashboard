require 'rails_helper'

describe ServiceProviderImporter do
  let(:good_file) { File.join(file_fixture_path, 'extract_sample.json') }

  before do
    # Ensure at least one logingov_admin user exists
    # This is currently used by the importer as a fall-back user
    create(:user, :logingov_admin)
  end

  context 'with new, reasonable data' do
    subject(:importer) { described_class.new(good_file) }

    before do
      # An agency with this ID is required by the fixture data. Might as well use the prod value
      create(:agency, id: 130, name: 'Public Defender Service for the District of Columbia')
    end

    # Happy path integration test
    it 'can inspect and save the data' do
      expected_issuers = [
        'urn:gov:gsa:openidconnect.profiles:sp:sso:gsa:sandbox-test',
        'urn:gov:gsa:openidconnect.profiles:sp:sso:agency_name:help_text',
        '2024-10-15:non-admin:test',
        '2024-10-17:helptext',
        '2024-11-06-mobile-test',
        'asdfsadfasd',
        'asdfsadfas',
        '2025-01-13:fields:test',
        '2024-01-09:saml:test',
        '2024-10-18-helptext',
      ]
      expected_user = Team.internal_team.users.first
      expected_team_uuids = [
        '27f565d5-4d60-4cc5-8e8d-90a8fd2bd3aa',
        '27f565d5-4d60-4cc5-8e8d-90a8fd2bd3aa',
        # In the fixture, this is missing a uuid, so should fall back to internal team
        Team.internal_team.uuid,
        '963bcc0a-2bd7-4762-8f59-a326e141970f',
        '27f565d5-4d60-4cc5-8e8d-90a8fd2bd3aa',
        '963bcc0a-2bd7-4762-8f59-a326e141970f',
        '27f565d5-4d60-4cc5-8e8d-90a8fd2bd3aa',
        '27f565d5-4d60-4cc5-8e8d-90a8fd2bd3aa',
        '27f565d5-4d60-4cc5-8e8d-90a8fd2bd3aa',
        '27f565d5-4d60-4cc5-8e8d-90a8fd2bd3aa',
      ]

      expect { importer.run }.to change { ServiceProvider.count }.by expected_issuers.count

      expect(importer.data.to_json).to eq(File.read(good_file))
      # Order doesn't matter much, so sort both arrays before comparing
      expect(importer.data.map { |sp| sp['issuer'] }.sort).to eq(expected_issuers.sort)
      expect(importer.models.map(&:persisted?)).to be_all
      expect(importer.models.map(&:issuer).sort).to eq(expected_issuers.sort)
      saved_models = ServiceProvider.last(expected_issuers.count)
      saved_models.each_with_index do |model, index|
        expect(importer.models).to include(model)
        expect(model.user).to eq(expected_user)
        expect(model.team).to eq(Team.find_by(uuid: expected_team_uuids[index]))
      end
    end

    it 'is idempotent' do
      expect { importer.run }.to change { ServiceProvider.count }.by 10
      expect { importer.run }.to_not change { ServiceProvider.count }
    end

    it 'can do a dry run' do
      importer.dry_run = true
      expect { importer.run }.to_not change { ServiceProvider.count }
    end
  end

  context 'with a conflicting entry in the database' do
    let(:duplicate_issuer) { '2025-01-13:fields:test' }

    before do
      create(:service_provider, issuer: duplicate_issuer)
    end

    subject(:importer) { described_class.new(good_file) }

    it 'saves nothing' do
      expect { importer.run }.to_not change { ServiceProvider.count }
      expect(importer.models.map(&:persisted?)).to be_none
    end

    it 'has an error only for the conflicting entry' do
      errors = importer.run
      expect(errors[duplicate_issuer].full_messages).to eq(['Issuer has already been taken'])
      errors.delete duplicate_issuer
      expect(errors.values.map(&:any?)).to be_none
    end
  end

  it 'errors with an invalid file name' do
    file_name = 'this file name is never going to exist'
    importer = described_class.new(file_name)
    expect { importer.run }.to raise_error(ArgumentError)
    expect(importer.data).to be_blank
    expect(importer.models).to be_blank
  end
end
