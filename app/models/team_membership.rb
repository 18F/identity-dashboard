# TeamMembership connects a single User, Team, and Role.
#
# This is the only record of the Role for that User/Team combination.
# Users and Teams are associated with each other through their own models.
class TeamMembership < ApplicationRecord
  has_paper_trail on: %i[create update destroy]

  belongs_to :role,
             foreign_key: 'role_name',
             primary_key: 'name',
             inverse_of: 'team_membership',
             optional: true
  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :team_memberships

  validates :user_id, uniqueness: { scope: :group_id, on: :create }
  validate :role_exists_if_present

  def self.find_or_build_logingov_admin(user)
    raise ActiveRecord::RecordNotFound unless Team.internal_team

    find_or_initialize_by(user: user, team: Team.internal_team, role: Role::LOGINGOV_ADMIN)
  end

  def self.find_or_build_logingov_readonly(user)
    raise ActiveRecord::RecordNotFound unless Team.internal_team

    find_or_initialize_by(user: user, team: Team.internal_team, role: Role::LOGINGOV_READONLY)
  end

  def self.destroy_orphaned_memberships(logger: nil)
    data_for_deleted_users = TeamMembership.where.missing(:user)
    if data_for_deleted_users.any?
      logger&.warn("Deleting team memberships #{data_for_deleted_users.map(&:id)} missing user IDs")
      data_for_deleted_users.destroy_all
    end

    data_for_deleted_teams = TeamMembership.where.missing(:team)
    return unless data_for_deleted_teams.any?

    logger&.warn("Deleting team memberships #{data_for_deleted_teams.map(&:id)} missing team IDs")
    data_for_deleted_teams.destroy_all
  end

  def role_exists_if_present
    return unless role_name

    unless Role.find_by(name: role_name)
      errors.add(:role_name, :invalid)
      return false
    end
    true
  end

  def set_default_role
    return if self.role_name
    self.role_name = 'partner_admin' and return if team.missing_a_partner_admin?
    self.role_name = 'partner_readonly' and return if IdentityConfig.store.prod_like_env

    self.role_name = 'partner_developer'
  end
end
