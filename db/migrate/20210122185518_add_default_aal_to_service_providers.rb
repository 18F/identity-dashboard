class AddDefaultAalToServiceProviders < ActiveRecord::Migration[6.0]
  def change
    add_column :service_providers, :default_aal, :integer
  end
end
