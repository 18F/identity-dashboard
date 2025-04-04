# PopulateRole designed to be invoked from a rake task
# as such, uses puts() instead of logger
include TeamHelper

class PopulateRoles
  USAGE_WARNING = <<-WARN.strip.freeze
      WARNING: this will loop through all UserTeams with invalid or nil roles and reset roles based on legacy permissions
    WARN

  VALID_ROLENAMES = %w[partner_admin partner_developer partner_readonly logingov_admin]

  def initialize(logger)
    @logger = logger
    @logger.warn(USAGE_WARNING)
    @userteamswithoutrole = UserTeam.where(role_name: nil)
      .or UserTeam.where.not(role_name: PopulateRoles::VALID_ROLENAMES)
    # check against array of exact role names (not friendly names)
    @logger.info(@userteamswithoutrole)
  end

  def call
    if @userteamswithoutrole.length == 0
      @logger.info('INFO: All UserTeams already have valid roles.')
    end
    begin
      @userteamswithoutrole.each do |userteam|
        user = get_user(userteam)
        role = get_legacy_role(user)
        set_role(userteam, role)
        @logger.info("User #{user.email} role updated to #{role}")
      end
    rescue StandardError => err
      @logger.warn("ERROR: #{err}")
    end
    @logger.info('SUCCESS: All invalid UserTeams have been updated')
  end

    private

  def get_user(userteam)
    User.find(userteam.user_id)
  end

  def get_legacy_role(user)
    # partner_admin = legacy allowlisted
    return 'partner_admin' if allowlisted_user?(user)

    'partner_developer'
  end

  def set_role(userteam, role)
    userteam.role = Role.find_by(name: role)
    userteam.save!
  end

end
