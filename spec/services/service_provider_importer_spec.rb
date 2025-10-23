require 'rails_helper'

describe ServiceProviderImporter do
  let(:good_file) { File.join(file_fixture_path, 'extract_sample.json') }

  before do
    # Ensure at least one logingov_admin user exists
    # This is currently used by the importer as a fall-back user
    create(:user, :logingov_admin)
    create(:agency, id: 106, name: 'National Nuclear Security Administration')
    create(:agency, id: 31, name: 'AbilityOne Commission')
  end

  context 'with ursula portal generated data' do
    subject(:importer) { described_class.new(good_file) }

    describe 'successful import' do
      let(:expected_issuers) do
        [
          'howard:test',
          'hello_banana_fire_ball',
          '04:24:test:aj',
          'urn:gov:gsa:openidconnect.profiles:sp:sso:agency_name:05291148',
          '654756876587697863453242',
        ]
      end
      let(:expected_user) { Team.internal_team.users.first }
      # This includes duplicates because multiple SPs can belong to the same team
      let(:expected_team_uuids) do
        %w[
          69c251d7-0185-4550-b2bc-de2834e08e2f
          69c251d7-0185-4550-b2bc-de2834e08e2f
          ab2cceb7-9ef5-4ae6-880d-bd0b6ae938a8
          706d3dc2-287b-4873-85da-1025dcd9b635
          6a12003a-c17c-4838-8381-f1f26cfe9498
        ]
      end

      it 'updates the team data' do
        expect(Team.where(uuid: expected_team_uuids)).to be_empty
        importer.run
        expect(importer.data.to_json['teams']).to eq(File.read(good_file)['teams'])
        expect(Team.where(uuid: expected_team_uuids).count).to eq expected_team_uuids.uniq.count
      end

      it 'updates the service provider data' do
        expect { importer.run }.to change { ServiceProvider.count }.by expected_issuers.count
        # Order doesn't matter much, so sort both arrays before comparing
        expect(importer.data['service_providers'].map do |sp|
          sp['issuer']
        end.sort).to eq(expected_issuers.sort)
        expect(importer.service_providers.map(&:persisted?)).to be_all
        expect(importer.service_providers.map(&:issuer).sort).to eq(expected_issuers.sort)
        saved_models = ServiceProvider.last(expected_issuers.count)
        saved_models.each_with_index do |model, index|
          expect(importer.service_providers).to include(model)
          expect(model.user).to eq(expected_user)
          expect(model.team).to eq(Team.find_by(uuid: expected_team_uuids[index]))
        end
      end
    end

    it 'it creates service provider with internal team if no team uuid is present' do
      importer = described_class.new(File.join(file_fixture_path, 'extract_sample_no_team.json'))
      expect { importer.run }.to change { ServiceProvider.count }.by 1
      data_from_file = importer.data
      saved_sp = ServiceProvider.find_by issuer: data_from_file['service_providers'].first['issuer']
      expect(saved_sp.team).to eq(Team.internal_team)
    end

    it 'is idempotent' do
      expect { importer.run }.to change { ServiceProvider.count }.by 5
      expect { importer.run }.to_not change { ServiceProvider.count }
    end

    it 'can do a dry run' do
      importer.dry_run = true
      expect { importer.run }.to_not change { ServiceProvider.count }
      expect { importer.run }.to_not change { Team.count }
    end

    it 'will not honor DB IDs' do
      data_from_file = JSON.parse(File.read(File.join(file_fixture_path, 'extract_sample.json')))
      conflicting_id = data_from_file['service_providers'].first['id']
      create(:service_provider, id: conflicting_id)

      expect { importer.run }.to change { ServiceProvider.count }.by 5
      issuer_from_file = data_from_file['service_providers'].first['issuer']
      saved_sp = ServiceProvider.find_by issuer: issuer_from_file
      expect(saved_sp.id).to_not eq(conflicting_id)
    end
  end

  context 'with a conflicting entry in the database' do
    let(:duplicate_issuer) { 'howard:test' }

    before do
      create(:service_provider, issuer: duplicate_issuer)
    end

    subject(:importer) { described_class.new(good_file) }

    it 'saves nothing' do
      expect { importer.run }.to_not change { ServiceProvider.count }
      expect(importer.service_providers.map(&:persisted?)).to be_none
    end

    it 'has an error only for the conflicting entry' do
      errors = importer.run
<<<<<<< HEAD
      conflict_msgs = errors[:service_provider_errors][duplicate_issuer].full_messages
      expect(conflict_msgs).to eq(['Issuer has already been taken'])
=======
      expect(errors[:service_provider_errors][duplicate_issuer].full_messages).to eq(['Issuer has already been taken'])
>>>>>>> 1c12b266 (updating extracts.rake to output team data and do dry run properly for teams)
      errors[:service_provider_errors].delete duplicate_issuer
      expect(errors[:service_provider_errors].values.map(&:any?)).to be_none
    end
  end

  it 'errors with an invalid file name' do
    file_name = 'this file name is never going to exist'
    importer = described_class.new(file_name)
    expect { importer.run }.to raise_error(ArgumentError)
    expect(importer.data).to be_blank
    expect(importer.service_providers).to be_blank
    expect(importer.teams).to be_blank
  end
end
