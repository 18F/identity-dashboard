class AddEnvironmentToServiceProvider < ActiveRecord::Migration[5.2]
  def change
    add_column :service_providers, :environment, :integer
  end
end
