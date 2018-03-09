class ServiceProviderActiveByDefault < ActiveRecord::Migration
  def change
    change_column_default(:service_providers, :active, true)
  end
end
