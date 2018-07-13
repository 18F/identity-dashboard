class RequireServiceProviderFriendlyName < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:service_providers, :friendly_name, false)
  end
end
