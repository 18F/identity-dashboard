# TeamMembershipAuditEvent allows us to turn PaperTrail::Version data about the join table 
# into something more presentable 
class TeamMembershipAuditEvent < Struct.new(:event, :created_at, :whodunnit, :changes, :id)
  EVENT_RENAMING = {'create' => 'add', 'destroy' => 'remove'}.freeze

  # Accepts a team ID and optionally a PaperTrail::Version scope
  def self.versions_by_team_id(team_id, scope: PaperTrail::Version.all)
    scope.
      where(item_type: 'UserTeam').
      where(%(object_changes @> '{"group_id":[?]}'), team_id).
      or(
        # In theory, nothing in the current application can intentionally null out the group_id
        # without deleting the user, too, but let's check for that just to be safe.
        scope.
          where(item_type: 'UserTeam').
          where(%(object @> '{"group_id":?}'), team_id),
      )
  end

  def self.from_version(version)
    if version.item_type != 'UserTeam'
      raise ArgumentError.new("Version #{version.id} is not a UserTeam change")
    end

    # The ID column for the UserTeam table doesn't matter much here
    version.object_changes.delete('id')
    new(
      EVENT_RENAMING.fetch(version.event, version.event),
      version.created_at,
      version.whodunnit,
      version.object_changes,
    )
  end

  def object_changes
    changes['user_email'] ||= changes['user_id'].map {|user_id| User.find_by(id: user_id)&.email }
    changes
  end

  def user_email
    object_changes['user_email'].compact.first
  end
end
