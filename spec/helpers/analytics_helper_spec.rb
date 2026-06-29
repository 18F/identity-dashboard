require 'rails_helper'

describe AnalyticsHelper do
  describe '#teams_collection_for_select' do
    describe 'when no teams are passed in' do
      let(:team) { [] }

      it 'returns an empty array' do
        expect(teams_collection_for_select([])).to eq([])
      end
    end

    describe 'when one team is passed in' do
      let(:team) { create(:team) }
      let(:result) do
        [
          {
            title: team.name,
            id: team.id,
            controls: stringified_uuid_list,
          },
        ]
      end

      describe 'when the team has no service_providers' do
        let(:stringified_uuid_list) { '' }

        it 'returns an empty string for the apps key' do
          expect(teams_collection_for_select([team])).to eq(result)
        end
      end

      describe 'when the team has a service_provider' do
        let!(:sp) { create(:service_provider, :consistent, team:) }
        let(:stringified_uuid_list) { sp.uuid.to_s }

        describe 'with no uuid' do
          let(:stringified_uuid_list) { '' }

          it 'returns the single uuid as a string' do
            expect(teams_collection_for_select([sp.team])).to eq(result)
          end
        end

        describe 'when the service provider has a uuid' do
          let!(:sp) { create(:service_provider, :ready_to_activate, team:) }

          it 'returns the single uuid as a string' do
            expect(teams_collection_for_select([sp.team])).to eq result
          end
        end
      end

      describe 'when there are multiple service_providers' do
        let!(:sp) { create(:service_provider, :ready_to_activate, team:, uuid: 'bbbb') }
        let!(:sp1) { create(:service_provider, :ready_to_activate, team:, uuid: 'aaaa') }
        let(:stringified_uuid_list) { "#{sp1.uuid},#{sp.uuid}" }

        it 'returns the sp uuids as a comma-separated string' do
          expect(teams_collection_for_select([team])).to eq result
        end
      end
    end

    describe 'when multiple teams are passed in' do
      let(:team) { create(:team, name: 'Zebra Team') }
      let(:team2) { create(:team, name: 'Alpha Team') }
      let!(:sp) { create(:service_provider, :consistent, team:, uuid: 'aa') }
      let!(:sp1) { create(:service_provider, :consistent, team:, uuid: 'bb') }
      let!(:sp3) { create(:service_provider, :consistent, team: team2, uuid: 'cc') }
      let!(:sp4) { create(:service_provider, :consistent, team: team2, uuid: 'dd') }
      let(:stringified_uuid_list) { "#{sp.uuid},#{sp1.uuid}" }
      let(:team2_stringified_uuid_list) { "#{sp3.uuid},#{sp4.uuid}" }

      let(:result) do
        [
          {
            title: team2.name,
            id: team2.id,
            controls: team2_stringified_uuid_list,
          },
          {
            title: team.name,
            id: team.id,
            controls: stringified_uuid_list,
          },
        ]
      end

      it 'returns the teams as a comma-separated string in alphabetical order' do
        expect(teams_collection_for_select([team, team2])).to eq result
      end
    end
  end

  describe '#service_providers_collection_for_select' do
    let(:current_user) { create(:user, :logingov_admin) }

    describe 'no sps are passed in' do
      it 'returns an empty array' do
        expect(service_providers_collection_for_select([])).to eq([])
      end
    end

    describe 'a single sp is passed in' do
      let(:sp) { create(:service_provider, :ready_to_activate) }

      it 'returns an array where the first object contains the sp name, uuid, and valid dates' do
        expect(service_providers_collection_for_select([sp])).to eq(
          [
            { title: sp.friendly_name, id: sp.uuid, controls: '' },
          ],
        )
      end
    end

    describe 'multiple sps are passed in' do
      let(:sp) { create(:service_provider, :ready_to_activate, friendly_name: 'Zebra Service') }
      let(:sp1) { create(:service_provider, :ready_to_activate, friendly_name: 'Alpha Service') }

      it 'returns an array of objects sorted alphabetically by friendly_name' do
        expect(service_providers_collection_for_select([sp, sp1])).to eq(
          [
            { title: sp1.friendly_name, id: sp1.uuid, controls: '' },
            { title: sp.friendly_name, id: sp.uuid, controls: '' },
          ],
        )
      end
    end
  end

  describe '#selected_date_range' do
    describe 'when no date is passed in' do
      let(:date) { nil }

      it 'returns No Date Range selected' do
        expect(selected_date_range(date)).to eq 'No date range selected'
      end
    end

    describe 'when a date is passed in' do
      let(:date) { '2025-04-01' }

      it 'returns a string of the date to the end of the month' do
        range_text = '2025-04-01 to 2025-04-30'
        expect(selected_date_range(date)).to eq range_text
      end

      describe 'when it is leap year' do
        let(:date) { '2024-02-12' }

        it 'returns the end of the month correctly' do
          range_text = '2024-02-12 to 2024-02-29'
          expect(selected_date_range(date)).to eq range_text
        end
      end
    end
  end

  describe '#all_app_options_string' do
    describe 'when no team is passed in' do
      let(:team) { nil }

      it 'returns No Date Range selected' do
        expect(all_app_options_string(team)).to eq ''
      end
    end

    describe 'when teams are passed in' do
      let(:team) { create(:team) }

      describe 'only one team' do
        describe 'with no service providers' do
          it 'returns an empty string' do
            expect(all_app_options_string([team])).to eq ''
          end
        end

        describe 'with one service provider' do
          let!(:sp) { create(:service_provider, :ready_to_activate, team:) }

          it 'returns the uuid in a string' do
            expect(all_app_options_string([team])).to eq sp.uuid.to_s
          end
        end

        describe 'with two service provider' do
          let!(:sp) { create(:service_provider, :ready_to_activate, team:, uuid: 'aaaa') }
          let!(:sp1) { create(:service_provider, :ready_to_activate, team:, uuid: 'bbbb') }

          it 'returns the uuid in a string' do
            expect(all_app_options_string([team])).to eq "#{sp.uuid},#{sp1.uuid}"
          end
        end
      end

      describe 'when multiple teams are passed in' do
        let(:team1) { create(:team) }
        let(:team2) { create(:team) }
        let!(:sp) { create(:service_provider, :ready_to_activate, team:) }
        let!(:sp1) { create(:service_provider, :ready_to_activate, team: team1) }
        let!(:sp2) { create(:service_provider, :ready_to_activate, team: team2) }

        it 'joins all the available uuids' do
          expected_result = "#{sp.uuid},#{sp1.uuid},#{sp2.uuid}"

          expect(all_app_options_string([team, team1, team2])).to eq expected_result
        end
      end
    end
  end

  describe '#permitted_teams' do
    let(:logingov_admin) { create(:user, :logingov_admin) }
    let(:user0) { create(:user) }
    let(:team0) { create(:team) }
    let(:team1) { create(:team) }
    let(:team2) { create(:team) }
    let!(:sp0) { create(:service_provider, :ready_to_activate, team: team0) }
    let!(:sp1) { create(:service_provider, :ready_to_activate, team: team1) }

    it 'returns all teams with configs for Login Admins' do
      current_user = logingov_admin

      expect(permitted_teams(current_user)).to include(team0, team1)
    end

    it 'returns all teams with configs where partner is Partner Admin' do
      current_user = user0

      create(:team_membership, :partner_admin, user: user0, team: team0)
      create(:team_membership, :partner_admin, user: user0, team: team2)
      create(:team_membership, :partner_developer, user: user0, team: team1)

      expect(permitted_teams(current_user)).to eq([team0])
    end
  end
end
