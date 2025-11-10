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

  ROLES_I18N_BUCKET = IdentityConfig.store.prod_like_env ?
    'role_names.production' :
    'role_names.sandbox'
  ACTIVE_ROLES_NAMES = {
    logingov_admin: I18n.t("#{ROLES_I18N_BUCKET}.logingov_admin"),
    partner_admin: I18n.t("#{ROLES_I18N_BUCKET}.partner_admin"),
    partner_developer: I18n.t("#{ROLES_I18N_BUCKET}.partner_developer"),
    partner_readonly: I18n.t("#{ROLES_I18N_BUCKET}.partner_readonly"),
  }.freeze
  LOGINGOV_ADMIN = Role.find_by(name: :logingov_admin)

  def friendly_name
    ACTIVE_ROLES_NAMES[self.name.to_sym]
  end
end
