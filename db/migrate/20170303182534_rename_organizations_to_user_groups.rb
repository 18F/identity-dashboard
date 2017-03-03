class RenameOrganizationsToUserGroups < ActiveRecord::Migration
  def up
    rename_column :organizations, :team_name, :name
    add_index :organizations, :name, unique: true

    remove_column :organizations, :department_name
    remove_column :organizations, :agency_name

    add_column :organizations, :description, :text, null: false

    rename_table :organizations, :user_groups
    rename_column :service_providers, :organization_id, :user_group_id
  end

  def down
    remove_index :user_groups, :name
    rename_column :user_groups, :name, :team_name

    add_column :user_groups, :department_name, :string, null: false
    add_column :user_groups, :agency_name, :string, null: false

    remove_column :user_groups, :description, :text

    add_index :user_groups,
      [:department_name, :agency_name, :team_name],
      unique: true,
      name: :index_organizations_on_name_fields

    rename_table :user_groups, :organizations
    rename_column :service_providers, :user_group_id, :organization_id
  end
end
