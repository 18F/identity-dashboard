class AddMultipleRedirectUris < ActiveRecord::Migration
  def up
    add_column :service_providers, :redirect_uris, :json

    execute <<-SQL
      UPDATE service_providers
      SET redirect_uris=array_to_json(ARRAY[redirect_uri])
      WHERE length(redirect_uri) > 0
    SQL
  end

  def down
    remove_column :service_providers, :redirect_uris, :json
  end
end
