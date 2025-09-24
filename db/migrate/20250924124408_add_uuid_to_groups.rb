require 'securerandom'

class AddUuidToGroups < ActiveRecord::Migration[7.2]
  def up
    add_column :groups, :uuid, :string
    add_index :groups, :uuid, unique: true

    # Update existing records with random UUIDs
    Team.all.each do |team| 
      team.update(uuid: SecureRandom.uuid)
    end
  end

  def down
    remove_column :groups, :uuid
  end
end