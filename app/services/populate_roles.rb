# PopulateRole designed to be invoked from a rake task
# as such, uses puts() instead of logger
# rubocop:disable Rails/Output
include TeamHelper

class PopulateRoles
    USAGE_WARNING = <<-WARN.strip.freeze
      WARNING: this will loop through all UserTeams without roles and set roles based on legacy permissions
    WARN
  
    def initialize()
        @userteamswithoutrole = UserTeam.all.where(role_name: nil)
    end
  
    def call
      @usersteamswithoutrole.each do |userteam|
        user = get_user(userteam)
        role = get_legacy_role(user)
        set_role(role)
      end
    end
  
    private
  
    def get_user(userteam)
        User.find(userteam.user_id)
    end

    def get_legacy_role(user)
        return 'login_admin' if user.admin?
        #partner_admin = legacy allowlisted
        return 'partner_admin' if allowlisted_user?(user)
        return 'partner_developer'
    end

    def set_role(role)
        userteam.role = Role.find_by(name: role)
        userteam.save!
    end

  end
  # rubocop:enable Rails/Output
  