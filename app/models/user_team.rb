class UserTeam < ApplicationRecord
  self.table_name = :user_groups

  has_paper_trail on: %i[create update destroy]

  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :user_teams

  validates_uniqueness_of :user_id, scope: :group_id, on: :create,
                          :message=> 'This user is already a member of the team.'
  validate :role_exists_if_present

  def role_exists_if_present
    return unless role_name
    unless Role.find role_name
      errors.add(:role_name, :invalid)
      return false
    end
    true
  end

  def role=(role)
    self.role_name = role.name
  end
end
