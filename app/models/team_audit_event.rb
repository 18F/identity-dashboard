# TeamAuditEvent allows us to pull both teams edits and team_users edits at once.
#
# It also can decorate the team_users edits so they we can pull consistent data out
# of both types of edits.
class TeamAuditEvent < Struct.new(:event, :created_at, :whodunnit, :changes, :id)
  EVENT_RENAMING = {'create' => 'add', 'destroy' => 'remove'}.freeze

  # TeamAuditEvent.by_team(team, scope: )
  #
  # `team` should be a Team instance that's been persisted. Instances not saved to the db
  # won't have an audit trail yet
  #
  # `scope` should be a pundit policy scope whenever one is applicable
  #
  # This code probably knows too much about how PaperTrail::Version works.
  # This rubs up against the ways ActiveRecord can be frustrating.
  # Thankfully, PaperTrail has been very stable.
  #
  # This returns an Active::Record collection and does not do the decorating so that it could
  # be tested separately.
  def self.by_team(team, scope: PaperTrail::Version.all)
    # PaperTrail has a default order, so we have to be consistently explicit about reordering
    newest_first_scope = scope.reorder(created_at: :desc)
    membership_versions = TeamAuditEvent.membership_versions_by_team(
      team,
      scope: newest_first_scope,
    )
    team_versions = newest_first_scope.where(item_type: 'Team', item_id: team.id)

    membership_versions.or(team_versions).where(created_at: 1.year.ago..Time.zone.now)
  end

  # TeamAuditEvent.decorate(scope)
  #
  # `scope` is usually an ActiveRecord::Collection returned by `TeamAuditEvent.by_team`
  # though it should work with any ActiveRecord::Model collection from PaperTrail::Version
  def self.decorate(scope)
    # The team membership changes need some decoration. The PaperTrail information on
    # just the `UserTeam` join table itself isn't helpful to an end user.
    scope.map do |v|
      v.item_type == 'UserTeam' ? TeamAuditEvent.from_membership_version(v) : v
    end
  end

  # Accepts a team and optionally a PaperTrail::Version scope
  def self.membership_versions_by_team(team, scope: PaperTrail::Version.all)
    team_id = team.id
    if team_id.blank?
      raise ArgumentError.new("Team #{team.name} is missing a team ID. Has it been saved yet?")
    end

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

  def self.from_membership_version(version)
    if version.item_type != 'UserTeam'
      raise ArgumentError.new("Version #{version.id} is not a UserTeam change")
    end

    object_changes = version.object_changes

    # The ID column for the UserTeam table doesn't matter much here
    object_changes.delete('id')

    # Use the user ID as an identifier
    user_id = version.object['user_id'] if version.object
    # We could put the user_id as both "previous" and "updated" value but
    # I feel like that makes it harder to read
    object_changes['user_id'] ||= [user_id, nil]

    new(
      EVENT_RENAMING.fetch(version.event, version.event),
      version.created_at,
      version.whodunnit,
      version.object_changes,
      object_changes['user_id'].compact.first,
    )
  end

  def object_changes
    changes['user_email'] ||= changes['user_id'].map { |user_id| User.find_by(id: user_id)&.email }
    changes
  end

  def user_email
    object_changes['user_email'].compact.first
  end
end
