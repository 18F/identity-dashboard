class AddApplicationApprovedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :applications, :approved, :boolean, null: false, default: false
  end
end
