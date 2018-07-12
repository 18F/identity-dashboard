class UserGroupHasManyUsers < ActiveRecord::Migration[4.2]
  def change
    add_reference :users, :user_group, index: true
  end
end
