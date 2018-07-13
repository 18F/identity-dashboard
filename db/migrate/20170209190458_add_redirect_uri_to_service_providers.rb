class AddRedirectUriToServiceProviders < ActiveRecord::Migration[4.2]
  def change
    add_column :service_providers, :redirect_uri, :string
  end
end
