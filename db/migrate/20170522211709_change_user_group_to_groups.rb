class ChangeUserGroupToGroups < ActiveRecord::Migration[4.2]
  def change
    rename_table :user_groups, :groups
    rename_column :users, :user_group_id, :group_id
    rename_column :service_providers, :user_group_id, :group_id
  end
end
