require 'rails_helper'

RSpec.describe Seeders::Teams do
  let(:logger) { Rails.logger }

  before do
    allow(logger).to receive(:info).with(any_args)
  end

  context 'without the team in place' do
    before do
      Team.find_by(name: Team::INTERNAL_TEAM_NAME)&.destroy!
    end
    it 'initializes the Logingov team' do
      expect do
        described_class.new.seed
      end.to change { Team.count }.by 1

      last_team = Team.last
      internal_agency_data = Seeders::AgencySeeder.internal_agency_data
      expect(last_team.name).to eq Team::INTERNAL_TEAM_NAME
      expect(last_team.description).to eq Team::INTERNAL_TEAM_DESCRIPTION
      expect(last_team.agency.name).to eq internal_agency_data[:name]

      expected_attributes = {
        name: Team::INTERNAL_TEAM_NAME,
        description: Team::INTERNAL_TEAM_DESCRIPTION,
        agency_id: internal_agency_data[:id],
        uuid: 'e5b7ca57-aabd-857f-9d9a-a59a46116e93',
      }
      expect(logger).to have_received(:info).with 'Created internal team ID ' \
        "'#{last_team.id}' with attributes '#{expected_attributes}'"
    end
  end

  it 'does not initialize if the team name already exists' do
    Team.find_by! name: Team::INTERNAL_TEAM_NAME

    expect do
      described_class.new.seed
    end.to_not change { Team.count }

    expect(logger).to_not have_received(:info)
  end
end
