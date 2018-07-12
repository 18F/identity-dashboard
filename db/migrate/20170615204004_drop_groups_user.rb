class DropGroupsUser < ActiveRecord::Migration[4.2]
  def change
    drop_table :groups_users
  end
end
