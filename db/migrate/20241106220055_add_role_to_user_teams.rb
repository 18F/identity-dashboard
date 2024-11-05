class AddRoleToUserTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :user_groups, :role_name, :string, null: true
    add_foreign_key :user_groups, :roles, column: :role_name, primary_key: :name
  end
end
