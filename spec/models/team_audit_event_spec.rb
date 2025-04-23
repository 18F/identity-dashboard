require 'rails_helper'

RSpec.describe TeamAuditEvent do
  describe 'integration', versioning: true do
    it 'can find creations and deletions' do
      PaperTrail.config.version_limit = nil
      team = create(:team)
      wrong_team = create(:team)
      added_admin_user = create(:user, admin: true)
      added_and_removed_user = create(:user)
      added_and_destroyed_user = create(:user)
      wrong_user = create(:user)

      team.users << added_admin_user

      team.users << added_and_removed_user
      team.users.delete(added_and_removed_user)

      team.users << added_and_destroyed_user
      added_and_destroyed_user.destroy!

      wrong_team.users << wrong_user

      expect(team.users.count).to be(1)
      expect(team.users[0]).to eq(added_admin_user)

      trail = TeamAuditEvent.decorate(TeamAuditEvent.by_team(
        team,
        scope: Pundit.policy_scope(added_admin_user, PaperTrail::Version),
      ))

      # most recent first
      expect(trail[0].event).to eq('remove')
      expect(trail[0].user_email).to eq(nil) # Looking up emails of destroyed users may come later
      expect(trail[0].object_changes['user_id']).to eq([added_and_destroyed_user.id, nil])

      expect(trail[1].event).to eq('add')
      expect(trail[1].user_email).to eq(nil) # Looking up emails of destroyed users may come later
      expect(trail[1].object_changes['user_id']).to eq([nil, added_and_destroyed_user.id])

      expect(trail[2].event).to eq('remove')
      expect(trail[2].user_email).to eq(added_and_removed_user.email)
      expect(trail[2].object_changes['user_id']).to eq([added_and_removed_user.id, nil])

      expect(trail[3].event).to eq('add')
      expect(trail[3].user_email).to eq(added_and_removed_user.email)
      expect(trail[3].object_changes['user_id']).to eq([nil, added_and_removed_user.id])

      expect(trail[4].event).to eq('add')
      expect(trail[4].user_email).to eq(added_admin_user.email)
      expect(trail[4].object_changes['user_id']).to eq([nil, added_admin_user.id])

      expect(trail[5].event).to eq('create')
      expect(trail[5].item_id).to eq(team.id)

      expect(trail.count).to be(6)
    end

    it 'can handle role changes as well as other changes' do
      user_membership = create(:user_team, :partner_admin)
      team = user_membership.team
      user_membership.role = Role.find_by(name: 'partner_developer')
      user_membership.save!
      audit_events = TeamAuditEvent.decorate(TeamAuditEvent.by_team(team))
      object_changes = audit_events.map(&:object_changes)

      role_change = object_changes.first
      expect(role_change['role_name']).to eq(['partner_admin', 'partner_developer'])
      expect(role_change['user_email']).to eq([user_membership.user.email, nil])
      expect(role_change['user_id']).to eq([user_membership.user.id, nil])
      # No created_at timestamps should show for actions that are only edits
      expect(role_change['created_at']).to eq(nil)

      user_addition = object_changes.second
      expect(user_addition['role_name']).to eq([nil, 'partner_admin'])
      expect(user_addition['user_email']).to eq([nil, user_membership.user.email])
      expect(user_addition['user_id']).to eq([nil, user_membership.user.id])

      # It's difficult to compare date strings without normalizing them first
      expect(user_addition['created_at'].first).to be_nil
      expected_created_date = user_membership.user.created_at.to_datetime
      expect(DateTime.parse(user_addition['created_at'].last))
        .to be_within(2.seconds)
        .of(expected_created_date)
    end
  end

  describe '.decorate' do
    it 'does not make further DB queries by default' do
      mocked_entry = double(PaperTrail::Version.new)
      expect(mocked_entry).to receive(:item_type).and_return('')
      mock_scope = [mocked_entry]
      TeamAuditEvent.decorate(mock_scope)
    end

    it 'looks up TeamUser event email addresses' do
      user = create(:user)
      entry = PaperTrail::Version.new(
        item_type: 'UserTeam',
        object_changes: { 'user_id' => [nil, user.id] },
      )
      results = TeamAuditEvent.decorate([entry])
      expect(results.count).to be(1)
      expect(results[0].user_email).to eq(user.email)
    end
  end

  describe '.by_team' do
    it 'blocks membership with a supplied scope that might come from PaperTrail' do
      permission_denied_scope = PaperTrail::Version.none
      expected_denial_sql = permission_denied_scope.to_sql

      team = build(:team, id: rand(1..1000))
      generated_sql = TeamAuditEvent.by_team(
        team,
        scope: permission_denied_scope,
      ).to_sql
      expect(generated_sql).to include(expected_denial_sql)
    end

    it 'permits membership through a supplied scope' do
      permission_allowed_scope = PaperTrail::Version.all
      expected_allowal_sql = permission_allowed_scope.to_sql
      denial_sql = PaperTrail::Version.none.to_sql

      team = build(:team, id: rand(1..1000))
      generated_sql = TeamAuditEvent.by_team(
        team,
        scope: permission_allowed_scope,
      ).to_sql
      expect(generated_sql).to include(expected_allowal_sql)
      expect(generated_sql).to_not include(denial_sql)
    end
  end
end
