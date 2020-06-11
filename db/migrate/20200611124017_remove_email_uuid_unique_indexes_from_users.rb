class RemoveEmailUuidUniqueIndexesFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_index :users, column: :email, unique: true
    remove_index :users, column: :uuid, unique: true
  end
end
