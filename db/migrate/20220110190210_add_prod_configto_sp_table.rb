class AddProdConfigtoSpTable < ActiveRecord::Migration[6.1]
  def change
    add_column :service_providers, :prod_config, :boolean
  end
end
