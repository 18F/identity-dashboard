class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :agency
      t.string :department
      t.string :team

      t.timestamps null: false
    end
  end
end
