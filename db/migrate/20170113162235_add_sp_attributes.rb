class AddSpAttributes < ActiveRecord::Migration[4.2]
  def change
    add_column :service_providers, :agency, :string
    add_column :service_providers, :sp_initiated_login_url, :text
    add_column :service_providers, :return_to_sp_url, :text
  end
end
