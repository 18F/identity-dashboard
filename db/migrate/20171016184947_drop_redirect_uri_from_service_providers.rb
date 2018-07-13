class DropRedirectUriFromServiceProviders < ActiveRecord::Migration[4.2]
  def change
    remove_column :service_providers, :redirect_uri, :string
  end
end
