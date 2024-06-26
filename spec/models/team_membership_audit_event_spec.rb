require 'rails_helper'

RSpec.describe TeamMembershipAuditEvent do
  describe '.by_team_id', versioning: true do
    it 'can find creations and deletions' do
      PaperTrail.config.version_limit = nil
      team = create(:team)
      wrong_team = create(:team)
      added_user = create(:user)
      added_and_removed_user = create(:user)
      added_and_destroyed_user = create(:user)
      wrong_user = create(:user)

      team.users << added_user

      team.users << added_and_removed_user
      team.users.delete(added_and_removed_user)

      team.users << added_and_destroyed_user
      added_and_destroyed_user.destroy!

      wrong_team.users << wrong_user

      trail = TeamMembershipAuditEvent.from_versions(
        TeamMembershipAuditEvent.versions_by_team_id(team.id),
      )

      expect(trail[0].action).to eq('Added')
      expect(trail[0].user_id).to eq(added_user.id)

      expect(trail[1].action).to eq('Added')
      expect(trail[1].user_id).to eq(added_and_removed_user.id)

      expect(trail[2].action).to eq('Removed')
      expect(trail[2].user_id).to eq(added_and_removed_user.id)

      expect(trail[3].action).to eq('Added')
      expect(trail[3].user_id).to eq(added_and_destroyed_user.id)

      expect(trail[4].action).to eq('Removed')
      expect(trail[4].user_id).to eq(added_and_destroyed_user.id)

      expect(trail.count).to be(5)

      expect(team.users.count).to be(1)
      expect(team.users[0]).to eq(added_user)
    end

    it 'will block access with a supplied scope that might come from PaperTrail' do
      permission_denied_scope = PaperTrail::Version.none
      expected_denial_sql = permission_denied_scope.to_sql

      team_id = rand(1..1000)
      generated_sql = TeamMembershipAuditEvent.versions_by_team_id(
        team_id, 
        scope: permission_denied_scope,
      ).to_sql
      expect(generated_sql).to include(expected_denial_sql)
    end

    it 'will permit access through a supplied scope' do
      permission_allowed_scope = PaperTrail::Version.all
      expected_allowal_sql = permission_allowed_scope.to_sql
      denial_sql = PaperTrail::Version.none.to_sql

      team_id = rand(1..1000)
      generated_sql = TeamMembershipAuditEvent.versions_by_team_id(
        team_id, 
        scope: permission_allowed_scope,
      ).to_sql
      expect(generated_sql).to include(expected_allowal_sql)
      expect(generated_sql).to_not include(denial_sql)
    end
  end
end
