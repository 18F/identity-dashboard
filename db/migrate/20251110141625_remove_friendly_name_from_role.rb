class RemoveFriendlyNameFromRole < ActiveRecord::Migration[7.2]
  def change
    remove_column :roles, :friendly_name
  end
end
