class AddOrganizationToServiceProvider < ActiveRecord::Migration
  def change
    add_reference :service_providers, :organization, index: true, foreign_key: true
  end
end
