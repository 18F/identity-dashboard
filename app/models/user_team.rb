class UserTeam < ApplicationRecord
  self.table_name = :user_groups
  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :user_teams
end
