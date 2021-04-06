class RemoveServiceProvidersSAMLClientCert < ActiveRecord::Migration[6.1]
  def change
    remove_column :service_providers, :saml_client_cert, :string
  end
end
