class AddIalToServiceProviders < ActiveRecord::Migration[5.1]
  def change
    add_column :service_providers, :ial, :integer
  end
end
