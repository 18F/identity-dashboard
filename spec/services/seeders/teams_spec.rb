require 'rails_helper'

RSpec.describe Seeders::Teams do
  let(:logger) { Rails.logger }

  before do
    allow(logger).to receive(:info).with(any_args)
  end

  context 'without the team in place' do
    before do
      Team.find_by(name: described_class::INTERNAL_TEAM_NAME)&.destroy
    end
    it 'initializes the Logingov team' do
      expect do
        described_class.new.seed
      end.to change { Team.count }.by 1

      last_team = Team.last
      expect(last_team.name).to eq described_class::INTERNAL_TEAM_NAME
      expect(last_team.description).to eq described_class::DESCRIPTION
      expect(last_team.agency_id).to eq described_class::AGENCY_ID

      expected_attributes = {
        name: described_class::INTERNAL_TEAM_NAME,
        description: described_class::DESCRIPTION,
        agency_id: described_class::AGENCY_ID,
      }
      expect(logger).to have_received(:info).with "Created internal team ID " \
        "'#{last_team.id}' with attributes '#{expected_attributes}'"
    end
  end

  it 'does not initialize if the team name already exists' do
    unless Team.find_by name: described_class::INTERNAL_TEAM_NAME
      create(:team, name: described_class::INTERNAL_TEAM_NAME)
    end

    expect do
      described_class.new.seed
    end.to_not change { Team.count }

    expect(logger).to_not have_received(:info)
  end
end
