class AddApplicationApprovedFlag < ActiveRecord::Migration
  def change
    add_column :applications, :approved, :boolean, null: false, default: false
  end
end
