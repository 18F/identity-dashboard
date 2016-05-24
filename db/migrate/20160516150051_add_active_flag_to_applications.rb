class AddActiveFlagToApplications < ActiveRecord::Migration
  def change
    add_column :applications, :active, :boolean, null: false, default: false
  end
end
