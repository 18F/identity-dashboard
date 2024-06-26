# TeamMembershipAuditEvent allows us to turn PaperTrail::Version data about the join table 
# into something more presentable 
class TeamMembershipAuditEvent < Struct.new(:user_id, :user_email, :action, :date, :whodunnit)
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

  EVENT_RENAMING = {'create' => 'Added', 'destroy' => 'Removed'}

  def self.from_versions(versions)
    versions.map do |version|
      if version.item_type != 'UserTeam'
        raise ArgumentError.new("Version #{version.id} is not a UserTeam change")
      end

      # Currently only creates and deletes are possible here. Because of that,
      # `PaperTrail::Version#object_changes` will have a hash where the values are always
      # an array of two items, one of which is `nil`
      version_data = version.object_changes.each_with_object(Hash.new) do |(key, value), result|
        result[key] = [version.object_changes[key]].flatten.compact.first
      end
      new(
        version_data['user_id'],
        User.find_by(id: version_data['user_id'])&.email.to_s,
        EVENT_RENAMING.fetch(version.event, version.event),
        version.created_at,
        version.whodunnit,
      )
    end
  end
end
