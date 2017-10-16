class DropRedirectUriFromServiceProviders < ActiveRecord::Migration
  def change
    remove_column :service_providers, :redirect_uri, :string
  end
end
