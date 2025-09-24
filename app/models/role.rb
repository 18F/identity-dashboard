# A Role describes a user's role on teams.
# A role has a `name`, which is our internal name that will be consistent between environments
# and a `friendly_name` which can be easily edited without modifying the internal name.
#
# Things this class does not do:
#
# The assignment of which user has which role currently exists in the TeamMemberships table.
#
# The enforcement of permissions should occur through the relevant Pundit policy class for
# the object the user is accessing.
#
class Role < ApplicationRecord
  has_many :team_membership,
           foreign_key: 'role_name',
           primary_key: 'name',
           inverse_of: :role,
           # If we delete a role, still keep the team memberships of users assigned that role
           dependent: :nullify

  ACTIVE_ROLES_NAMES = {
    logingov_admin: 'Login.gov Admin',
    partner_admin: 'Partner Admin',
    partner_developer: 'Partner Developer',
    partner_readonly: 'Partner Readonly',
  }.freeze
  LOGINGOV_ADMIN = Role.find_by(name: :logingov_admin)
end
