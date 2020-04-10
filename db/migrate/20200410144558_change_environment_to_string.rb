class ChangeEnvironmentToString < ActiveRecord::Migration[5.2]
  def change
    change_column :service_providers, :environment, :string, :default => "int"
  end
end
