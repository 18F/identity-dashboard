class AddLogoToServiceProviders < ActiveRecord::Migration[4.2]
  def change
    add_column :service_providers, :logo, :string
  end
end
