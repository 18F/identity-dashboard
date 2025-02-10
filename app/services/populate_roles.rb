# PopulateRole designed to be invoked from a rake task
# as such, uses puts() instead of logger
# rubocop:disable Rails/Output

include TeamHelper

class PopulateRoles
    USAGE_WARNING = <<-WARN.strip.freeze
      WARNING: this will loop through all UserTeams with invalid or nil roles and reset roles based on legacy permissions
    WARN

    VALID_ROLENAMES = ["partner_admin", "partner_developer", "partner_readonly", "login_admin"]
  
    def initialize()
        puts USAGE_WARNING
        @userteamswithoutrole = UserTeam.all.where.not(role_name: VALID_ROLENAMES )
        # check against array of exact role names (not friendly names)
        puts @userteamswithoutrole
    end
  
    def call
      return puts("INFO: All UserTeams already have valid roles.") if @userteamswithoutrole.length == 0
      @userteamswithoutrole.each do |userteam|
        user = get_user(userteam)
        role = get_legacy_role(user)
        set_role(userteam, role)
        puts "User #{user.email} role updated to #{role}"
      end
      puts "SUCCESS: All invalid UserTeams have been updated"
    end
  
    private
  
    def get_user(userteam)
        User.find(userteam.user_id)
    end

    def get_legacy_role(user)
        #partner_admin = legacy allowlisted
        return 'partner_admin' if allowlisted_user?(user)
        return 'partner_developer'
    end

    def set_role(userteam, role)
        userteam.role = Role.find_by(name: role)
        userteam.save!
    end

  end
  # rubocop:enable Rails/Output
  