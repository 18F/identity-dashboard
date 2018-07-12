class ChangeNameToFriendlyName < ActiveRecord::Migration[4.2]
  def change
    rename_column :service_providers, :name, :friendly_name
  end
end
