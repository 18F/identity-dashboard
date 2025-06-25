class RenameUserTeamsToTeamMemberships < ActiveRecord::Migration[7.2]
  def change
    rename_table :user_groups, :team_memberships
  end
end
