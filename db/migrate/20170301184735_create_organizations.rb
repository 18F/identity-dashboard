class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.timestamps null: false
      t.string :department_name, null: false
      t.string :agency_name, null: false
      t.string :team_name, null: false
    end

    add_index :organizations,
      [:department_name, :agency_name, :team_name],
      unique: true,
      name: :index_organizations_on_name_fields
  end
end
