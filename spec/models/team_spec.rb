require 'rails_helper'

describe Team do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:user_team) { create(:user_team) }

  describe 'Associations' do
    it { should have_many(:users) }
    it { should have_many(:service_providers) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }

    it 'validates uniqueness of name' do
      name = 'good name'
      create(:team, name:)
      duplicate = build(:team, name:)

      expect(duplicate).not_to be_valid
    end
  end

  describe '.sorted' do
    it 'returns users in alpha ordered by email' do
      b_user = create(:user, email: 'b@example.com')
      c_user = create(:user, email: 'c@example.com')
      a_user = create(:user, email: 'a@example.com')

      expect(User.sorted).to eq([a_user, b_user, c_user])
    end
  end

  describe '#user_deletion_history', versioning: true do
    it 'returns user deletion_history from paper_trail' do
      user_team.destroy
      deletion_history = user_team.team.user_deletion_history
      expect(deletion_history.count).to eq(1)
    end
  end

  describe '#user_deletion_report_item' do
    it 'returns formated record from user_deletion_history' do
      history_record = {
        'id' => 1,
        'user_id' => 2,
        'group_id' => 3,
        'removed_at' => '2021-06-08T17:34:06Z',
        'whodunnit_id' => '1',
      }
      report_item = team.user_deletion_report_item(history_record)
      expect(report_item[:user_id]).to eq(2)
    end
  end

  describe '#user_deletion_history_report', versioning: true do
    it 'returns deletion history when no email is provided' do
      user_id = user_team.user_id
      user_team.destroy
      deletion_report = user_team.team.user_deletion_history_report
      expect(deletion_report.first[:user_id]).to eq(user_id)
    end
    it 'returns deletion history when email is provided' do
      user_id = user_team.user_id
      user_email = user_team.user.email
      user_team.destroy
      report = user_team.team.user_deletion_history_report(email: user_email)
      expect(report.first[:user_id]).to eq(user_id)
    end
    it 'returns deletion history when limit is provided' do
      user_id = user_team.user_id
      user_email = user_team.user.email
      user_team.destroy
      report = user_team.team.user_deletion_history_report(limit: 1)
      expect(report.count).to eq(1)
    end
  end

  describe 'paper_trail', versioning: true do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      expect { create(:team) }.to change(PaperTrail::Version, :count).by(1)
    end

    it 'tracks updates' do
      team = create(:team)

      expect { team.update!(name: 'Team Awesome') }.to change(PaperTrail::Version, :count).by(1)
    end

    it 'tracks deletion' do
      team = create(:team)

      expect { team.destroy }.to change(PaperTrail::Version, :count).by(1)
    end
  end

  describe '#to_s' do
    it 'returns the name' do
      expect(team.to_s).to eq team.name
    end
  end

  describe '#destroy' do
    it 'deletes team memberships but not the users' do
      membership = create(:user_team)
      team = membership.team
      user = membership.user
      team.destroy
      expect { team.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      user.reload
      expect(user).to be_valid
    end
  end
end
