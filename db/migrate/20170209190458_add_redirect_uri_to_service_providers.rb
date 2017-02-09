class AddRedirectUriToServiceProviders < ActiveRecord::Migration
  def change
    add_column :service_providers, :redirect_uri, :string
  end
end
