class AddLogoToServiceProviders < ActiveRecord::Migration
  def change
    add_column :service_providers, :logo, :string
  end
end
