class RemoveUserUuidNullConstraint < ActiveRecord::Migration
  def change
    change_column_null(:users, :uuid, true)
  end
end
