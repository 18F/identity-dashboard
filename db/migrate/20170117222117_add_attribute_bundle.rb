class AddAttributeBundle < ActiveRecord::Migration
  def change
    add_column :service_providers, :attribute_bundle, :json
  end
end
