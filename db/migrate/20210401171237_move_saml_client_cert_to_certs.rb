class MoveSamlClientCertToCerts < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute <<-SQL
      UPDATE service_providers
      SET certs = (CAST(saml_client_cert AS character varying) || certs)
      WHERE saml_client_cert <> ''
    SQL
  end
end
