class UserGroupHasManyUsers < ActiveRecord::Migration
  def change
    add_reference :users, :user_group, index: true
  end
end
