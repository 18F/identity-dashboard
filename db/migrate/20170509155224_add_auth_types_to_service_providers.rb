class AddAuthTypesToServiceProviders < ActiveRecord::Migration[4.2]
  def change
    add_column :service_providers, :identity_protocol, :integer, default: 0
  end
end
