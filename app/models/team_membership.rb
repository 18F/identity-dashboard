class TeamMembership < ApplicationRecord
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

  def self.migrate_logingov_admins(logger: nil, &block)
    users_to_migrate = User.where(admin: true)
    users_to_migrate.each do |user|
      new_membership = transaction do
        create_logingov_admin!(user)
        self.last
      end

      logger = block_given? ? block : ->(event_log) { Rails.logger.info event_log }

      logger.call "Created membership #{new_membership.id} for " \
          "user #{user.email} on team #{new_membership.team.id}"
    end
  end

  def self.create_logingov_admin!(user)
    raise ActiveRecord::RecordNotFound unless Team.internal_team

    create!(user: user, team: Team.internal_team, role: Role::LOGINGOV_ADMIN)
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
