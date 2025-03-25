require 'rails_helper'

RSpec.describe UserTeam, type: :model do
  describe '#user_id' do
    it {
      is_expected.to validate_uniqueness_of(:user_id).scoped_to(:group_id).
        with_message('This user is already a member of the team.')
    }
  end

  describe 'paper_trail', versioning: true do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      user = create(:user)
      team = create(:team)

      expect { create(:user_team, user:, team:) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks updates' do
      user_team = create(:user_team)
      other_team = create(:team)

      expect { user_team.update!(team: other_team) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks deletion' do
      user_team = create(:user_team)

      expect { user_team.destroy }.to change { PaperTrail::Version.count }.by(1)
    end
  end

  describe '#valid?' do
    it { is_expected.to allow_value(nil).for(:role_name) }
    it { is_expected.to allow_value('logingov_admin').for(:role_name) }
    it { is_expected.not_to allow_value('some_random_admin').for(:role_name) }
  end

  describe '.destroy_orphaned_memberships' do
    it 'does not delete a valid membership' do
      valid_membership1 = create(:user_team)
      valid_membership2 = create(:user_team, [:partner_admin, :partner_readonly].sample)
      UserTeam.destroy_orphaned_memberships
      valid_membership1.reload
      expect(valid_membership1).to be_valid
      valid_membership2.reload
      expect(valid_membership2).to be_valid
    end

    it 'deletes a membership with a null user' do
      valid_membership = create(:user_team)
      invalidated_membership = create(:user_team)
      invalidated_membership.update_column(:user_id, nil)
      UserTeam.destroy_orphaned_memberships
      expect { invalidated_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      valid_membership.reload
      expect(valid_membership).to be_valid
    end

    it 'deletes a membership with a null team' do
      valid_membership = create(:user_team)
      invalidated_membership = create(:user_team)
      invalidated_membership.update_column(:group_id, nil)
      UserTeam.destroy_orphaned_memberships
      expect { invalidated_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      valid_membership.reload
      expect(valid_membership).to be_valid
    end
  end
end
