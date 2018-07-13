class AddAgencyModel < ActiveRecord::Migration[4.2]
  def change
    create_table :agencies do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :agencies, :name, unique: true
  end
end
