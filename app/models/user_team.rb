class UserTeam < ApplicationRecord
  self.table_name = :user_groups

  has_paper_trail on: %i[create update destroy]

  belongs_to :role, foreign_key: 'role_name', primary_key: 'name', optional: true
  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :user_teams

  validates :user_id, uniqueness: { scope: :group_id, on: :create,
                                    message: 'This user is already a member of the team.' }
  validate :role_exists_if_present

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
