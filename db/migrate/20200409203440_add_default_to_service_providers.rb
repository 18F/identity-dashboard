class AddDefaultToServiceProviders < ActiveRecord::Migration[5.2]
  def change
    change_column :service_providers, :environment, :integer, :default => 0
  end
end
