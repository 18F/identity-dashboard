class AddAppNameToSp < ActiveRecord::Migration[6.1]
  def change
    add_column :service_providers, :app_name, :string, null: false, default: ''
  end
end