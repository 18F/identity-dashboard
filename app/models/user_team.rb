class UserTeam < ApplicationRecord
  self.table_name = :user_groups

  has_paper_trail on: %i[create update destroy]

  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :user_teams

  validates_uniqueness_of :user_id, scope: :group_id, on: :create,
                          :message=> 'This user is already a member of the team.'
end
