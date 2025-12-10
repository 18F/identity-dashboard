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

  ROLES_NAMES = %w[
    logingov_admin
    logingov_readonly
    partner_admin
    partner_developer
    partner_readonly
  ]

  LOGINGOV_ADMIN = Role.find_by(name: :logingov_admin)
  LOGINGOV_READONLY = Role.find_by(name: :logingov_readonly)
  PARTNER_ADMIN = Role.find_by(name: :partner_admin)
  PARTNER_READONLY = Role.find_by(name: :partner_readonly)

  def self.active_friendly_names
    active_roles_names.invert
  end

  def self.active_roles_names
    @active_roles_names || ROLES_NAMES.map do |role|
      [role, I18n.t("#{roles_i18n_bucket}.#{role}")]
    end.to_h
  end

  def self.login_staff?(role)
    role == Role::LOGINGOV_ADMIN || role == Role::LOGINGOV_READONLY
  end

  def friendly_name
    Role.active_roles_names[self.name]
  end

  private_class_method

  def self.roles_i18n_bucket
    return 'role_names.production' if IdentityConfig.store.prod_like_env

    'role_names.sandbox'
  end
end
