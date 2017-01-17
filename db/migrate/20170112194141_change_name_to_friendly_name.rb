class ChangeNameToFriendlyName < ActiveRecord::Migration
  def change
    rename_column :service_providers, :name, :friendly_name
  end
end
