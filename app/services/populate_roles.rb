# PopulateRole designed to be invoked from a rake task.
# as such, uses puts() instead of logger
class PopulateRoles
  include TeamHelper

  USAGE_WARNING = <<-WARN.strip.freeze
      WARNING: this will loop through all TeamMemberships with invalid or nil roles and reset roles based on legacy permissions
  WARN

  VALID_ROLENAMES = %w[
    partner_admin
    partner_developer
    partner_readonly
    logingov_readonly
    logingov_admin
  ]

  def initialize(logger)
    @logger = logger
    @logger.warn(USAGE_WARNING)
    @team_memberships_without_role = TeamMembership.where(role_name: nil)
      .or TeamMembership.where.not(role_name: PopulateRoles::VALID_ROLENAMES)
    # check against array of exact role names (not friendly names)
    @logger.info(@team_memberships_without_role)
  end

  def call
    if @team_memberships_without_role.empty?
      @logger.info('INFO: All TeamMemberships already have valid roles.')
    end
    begin
      @team_memberships_without_role.each do |membership|
        user = get_user(membership)
        role = get_legacy_role(user)
        set_role(membership, role)
        @logger.info("User #{user.email} role updated to #{role}")
      end
    rescue StandardError => err
      @logger.warn("ERROR: #{err}")
    end
    @logger.info('SUCCESS: All invalid TeamMemberships have been updated')
  end

  private

  def get_user(team_membership)
    User.find(team_membership.user_id)
  end

  def get_legacy_role(user)
    # partner_admin = legacy allowlisted
    return 'partner_admin' if allowlisted_user?(user)

    'partner_developer'
  end

  def set_role(team_membership, role)
    team_membership.role = Role.find_by(name: role)
    team_membership.save!
  end
end
