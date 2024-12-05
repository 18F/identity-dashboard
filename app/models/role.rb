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
class Role
  attr_reader :name, :friendly_name

  # Don't use `Role.new` from outside the class itself.
  # Generally, you'll want to use `Role.find_by` instead
  def initialize(name:, friendly_name: nil)
    @name = name
    @friendly_name = friendly_name || name
  end

  SITE_ADMIN = new(name: 'Login.gov Admin')

  ACTIVE_ROLES = [
    SITE_ADMIN,
    new(name: 'Partner Admin'),
    new(name: 'Partner Developer'),
    new(name: 'Partner Readonly'),
  ].freeze

  def self.find_by(name:)
    ACTIVE_ROLES.find {|r| r.name == name}
  end

  def legacy_admin?
    name == 'Login.gov Admin'
  end
end
