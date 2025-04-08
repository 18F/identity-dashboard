class AddStatusToServiceProvidersAgain < ActiveRecord::Migration[7.2]
  def change
    add_column :service_providers, :status, :string, default: 'pending'
  end
end
