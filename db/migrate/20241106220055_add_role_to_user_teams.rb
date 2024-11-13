class AddRoleToUserTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :user_groups, :role_name, :string, null: true
  end
end
