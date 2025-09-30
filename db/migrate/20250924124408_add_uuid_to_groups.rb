require 'securerandom'

class AddUuidToGroups < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    add_column :groups, :uuid, :string
    add_index :groups, :uuid, unique: true, algorithm: :concurrently

    # Update existing records with random UUIDs
    Team.unscoped.in_batches(of: 100) do |relation|
      relation.where(uuid: nil).each do |team| 
        team.update uuid: SecureRandom.uuid
      end
      sleep(0.01) # throttle
    end
  end

  def down
    remove_column :groups, :uuid
  end
end