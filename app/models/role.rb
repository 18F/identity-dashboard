# A Role describes a user's role on teams.
# A role has a `name`, which is our internal name that will be consistent between environments
# and a `friendly_name` which can be easily edited without modifying the internal name.
#
# Things this class does not do:
#
# The assignment of which user has which role currently exists in the UserTeams table.
#
# The enforcement of permissions should occur through the relevant Pundit policy class for
# the object the user is accessing.
#
class Role < ApplicationRecord
  has_many :user_team

  ACTIVE_ROLES = {
    :logingov_admin => 'Login.gov Admin',
    :partner_admin => 'Partner Admin',
    :partner_developer => 'Partner Developer',
    :partner_readonly => 'Partner Readonly',
  }.freeze
  SITE_ADMIN = Role.find_by(name: :logingov_admin)

  def legacy_admin?
    name == 'logingov_admin'
  end

  def self.initialize_roles
    Role::ACTIVE_ROLES.each do |name, friendly_name|
      if !Role.find_by(name:)
        Role.create(name:, friendly_name:)
        puts "#{name} added to roles as #{friendly_name}"
      end
    end
  end
end
