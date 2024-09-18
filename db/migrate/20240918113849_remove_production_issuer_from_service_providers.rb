class RemoveProductionIssuerFromServiceProviders < ActiveRecord::Migration[7.1]
  def change
    remove_column :service_providers, :production_issuer
  end
end
