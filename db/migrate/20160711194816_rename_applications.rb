class RenameApplications < ActiveRecord::Migration[4.2]
  def change
    rename_table :applications, :service_providers
  end
end
