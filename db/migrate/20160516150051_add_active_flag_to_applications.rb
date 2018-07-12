class AddActiveFlagToApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :applications, :active, :boolean, null: false, default: false
  end
end
