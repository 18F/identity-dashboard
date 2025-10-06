class TeamMembership < ApplicationRecord # :nodoc:
  has_paper_trail on: %i[create update destroy]

  belongs_to :role,
             foreign_key: 'role_name',
             primary_key: 'name',
             inverse_of: 'team_membership',
             optional: true
  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :team_memberships

  validates :user_id, uniqueness: { scope: :group_id, on: :create,
                                    message: 'This user is already a member of the team.' }
  validate :role_exists_if_present

  def self.find_or_build_logingov_admin(user)
    raise ActiveRecord::RecordNotFound unless Team.internal_team

    find_or_initialize_by(user: user, team: Team.internal_team, role: Role::LOGINGOV_ADMIN)
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
    self.role_name ||= team.missing_a_partner_admin? ? 'partner_admin' : 'partner_readonly'
  end
end
