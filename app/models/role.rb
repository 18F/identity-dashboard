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
  has_many :user_team,
    foreign_key: 'role_name',
    primary_key: 'name',
    inverse_of: :role,
    # If we delete a role, don't delete the fact that the user who had that role belongs to a team
    dependent: :nullify

  ACTIVE_ROLES_NAMES = {
    logingov_admin: 'Login.gov Admin',
    partner_admin: 'Partner Admin',
    partner_developer: 'Partner Developer',
    partner_readonly: 'Partner Readonly',
  }.freeze
  LOGINGOV_ADMIN = Role.find_by(name: :logingov_admin)

  def legacy_admin?
    name == 'logingov_admin'
  end

  def self.initialize_roles(&block)
    logger = block_given? ? block : ->(event_log) { Rails.logger.info event_log }
    Role::ACTIVE_ROLES_NAMES.each do |name, friendly_name|
      unless Role.find_by(name:)
        Role.create(name:, friendly_name:)
        logger.call "#{name} added to roles as #{friendly_name}"
      end
    end
  end
end
