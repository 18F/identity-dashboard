class AddAuthTypesToServiceProviders < ActiveRecord::Migration
  def change
    add_column :service_providers, :identity_protocol, :integer, default: 0
  end
end
