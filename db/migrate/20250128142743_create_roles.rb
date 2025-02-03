class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :friendly_name, null: false

      t.timestamps

      t.index :name
    end

    reversible do |direction|
      direction.up do
        Role.initialize_roles
      end
    end
  end
end
