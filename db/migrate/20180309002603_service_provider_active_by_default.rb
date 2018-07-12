class ServiceProviderActiveByDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default(:service_providers, :active, true)
  end
end
