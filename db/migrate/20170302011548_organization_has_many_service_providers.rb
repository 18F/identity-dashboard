class OrganizationHasManyServiceProviders < ActiveRecord::Migration[4.2]
  def change
    add_reference :service_providers, :organization, index: true, foreign_key: true
  end
end
