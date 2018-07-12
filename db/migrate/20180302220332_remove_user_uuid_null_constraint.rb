class RemoveUserUuidNullConstraint < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:users, :uuid, true)
  end
end
