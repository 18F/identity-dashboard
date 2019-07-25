class AddAgencyIdToGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :groups, :agency_id, :int
  end
end
