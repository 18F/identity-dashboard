class RenameApplications < ActiveRecord::Migration
  def change
    rename_table :applications, :service_providers
  end
end
