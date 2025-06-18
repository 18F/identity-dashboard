class RenameUserTeamsToMemberships < ActiveRecord::Migration[7.2]
  def change
    rename_table :user_groups, :memberships
  end
end
