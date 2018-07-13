class AddAttributeBundle < ActiveRecord::Migration[4.2]
  def change
    add_column :service_providers, :attribute_bundle, :json
  end
end
