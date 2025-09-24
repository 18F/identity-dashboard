require 'securerandom'

class AddUuidToGroups < ActiveRecord::Migration[7.2]
  def up
    add_column :groups, :uuid, :string
    add_index :groups, :uuid, unique: true

    change_column_default :groups, :uuid, from: nil, to: SecureRandom.uuid

    # Update existing records with random UUIDs
    Team.all.each do |team| 
      team.update(uuid: SecureRandom.uuid)
    end
  end

  def down
    remove_column :groups, :uuid
  end
end