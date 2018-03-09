class RequireServiceProviderFriendlyName < ActiveRecord::Migration
  def change
    change_column_null(:service_providers, :friendly_name, false)
  end
end
