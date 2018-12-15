class AddProductionIssuerToServiceProviders < ActiveRecord::Migration[4.2]
  def change
    add_column :service_providers, :production_issuer, :string
  end
end
