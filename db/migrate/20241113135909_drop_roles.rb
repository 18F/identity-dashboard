class DropRoles < ActiveRecord::Migration[7.1]
  def change
    # The table never got deployed to production but it did get
    # into staging environments, so it should be rolled back properly
    drop_table :roles do |t|
      t.string :name, null: false

      t.timestamps

      t.index ['name'], name: 'index_roles_on_name', unique: true
    end
  end
end
