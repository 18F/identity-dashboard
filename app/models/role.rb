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
  attr_reader :name, :friendly_name

  ACTIVE_ROLES = {
    'logingov_admin': 'Login.gov Admin',
    'partner_admin': 'Partner Admin',
    'partner_dev': 'Partner Developer',
    'partner_readonly': 'Partner Readonly',
  }.freeze
  SITE_ADMIN = {
    'name': 'logingov_admin',
    'friendly_name': ACTIVE_ROLES['logingov_admin'],
  }.freeze

  def legacy_admin?
    name == 'logingov_admin'
  end
end
