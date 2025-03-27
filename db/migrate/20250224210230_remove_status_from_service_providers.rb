class RemoveStatusFromServiceProviders < ActiveRecord::Migration[7.2]
  def change
    remove_column :service_providers, :status, :string, default: 'pending'
  end
end
