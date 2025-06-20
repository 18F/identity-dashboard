# PopulateRole designed to be invoked from a rake task
# as such, uses puts() instead of logger
include TeamHelper

class PopulateRoles
  USAGE_WARNING = <<-WARN.strip.freeze
      WARNING: this will loop through all Memberships with invalid or nil roles and reset roles based on legacy permissions
  WARN

  VALID_ROLENAMES = %w[partner_admin partner_developer partner_readonly logingov_admin]

  def initialize(logger)
    @logger = logger
    @logger.warn(USAGE_WARNING)
    @membershipswithoutrole = Membership.where(role_name: nil)
      .or Membership.where.not(role_name: PopulateRoles::VALID_ROLENAMES)
    # check against array of exact role names (not friendly names)
    @logger.info(@membershipswithoutrole)
  end

  def call
    if @membershipswithoutrole.length == 0
      @logger.info('INFO: All Memberships already have valid roles.')
    end
    begin
      @membershipswithoutrole.each do |membership|
        user = get_user(membership)
        role = get_legacy_role(user)
        set_role(membership, role)
        @logger.info("User #{user.email} role updated to #{role}")
      end
    rescue StandardError => err
      @logger.warn("ERROR: #{err}")
    end
    @logger.info('SUCCESS: All invalid Memberships have been updated')
  end

  private

  def get_user(membership)
    User.find(membership.user_id)
  end

  def get_legacy_role(user)
    # partner_admin = legacy allowlisted
    return 'partner_admin' if allowlisted_user?(user)

    'partner_developer'
  end

  def set_role(membership, role)
    membership.role = Role.find_by(name: role)
    membership.save!
  end
end
