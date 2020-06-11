class AddEmailUuidWhereDeletedAtIndexesToUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :email, name: "index_users_on_email", where: "(deleted_at IS NULL)"
    add_index :users, :uuid, name: "index_users_on_uuid", where: "(deleted_at IS NULL)"
  end
end
