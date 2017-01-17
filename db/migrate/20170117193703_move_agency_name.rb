class MoveAgencyName < ActiveRecord::Migration
  class ServiceProvider < ActiveRecord::Base
  end

  class Agency < ActiveRecord::Base
  end

  def up
    add_column :service_providers, :agency_id, :integer

    ServiceProvider.where.not(agency: nil).each do |sp|
      agency = Agency.find_or_create_by(name: sp.agency)
      sp.update_attributes(agency_id: agency.id)
    end

    remove_column :service_providers, :agency
    add_foreign_key :service_providers, :agencies
    change_column_null :service_providers, :agency_id, false
  end

  def down
    add_column :service_providers, :agency, :string

    ServiceProvider.where.not(agency_id: nil).each do |sp|
      agency = Agency.find(sp.agency_id)
      sp.update_attributes(agency: agency.name)
    end

    remove_column :service_providers, :agency_id
  end
end
