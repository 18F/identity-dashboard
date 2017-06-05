class MoveUsersToNewGroups < ActiveRecord::Migration
  def up
    execute <<-SQL
      INSERT INTO user_groups (user_id, group_id, created_at, updated_at)
      SELECT id, group_id, NOW(), NOW()
      FROM users
      WHERE group_id IS NOT NULL 
    SQL
  end
end
