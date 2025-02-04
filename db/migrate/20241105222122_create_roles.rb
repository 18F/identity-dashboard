class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false

      t.timestamps

      t.index ['name'], name: 'index_roles_on_name', unique: true
    end
  end
end
