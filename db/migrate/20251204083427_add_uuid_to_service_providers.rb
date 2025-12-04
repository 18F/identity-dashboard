require 'securerandom'

class AddUuidToServiceProviders < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  # Plain model class to avoid loading the full ServiceProvider with enums
  class ServiceProvider < ApplicationRecord
    self.table_name = 'service_providers'
  end

  def up
    add_column :service_providers, :uuid, :string
    add_index :service_providers, :uuid, unique: true, algorithm: :concurrently

    # Update existing records with random UUIDs
    ServiceProvider.unscoped.in_batches(of: 100) do |relation|
      relation.where(uuid: nil).each do |service_provider|
        service_provider.update uuid: SecureRandom.uuid
      end
      sleep(0.01) # throttle
    end
  end

  def down
    remove_column :service_providers, :uuid
  end
end
