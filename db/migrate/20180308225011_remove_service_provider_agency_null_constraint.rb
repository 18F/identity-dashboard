class RemoveServiceProviderAgencyNullConstraint < ActiveRecord::Migration
  def change
    change_column_null(:service_providers, :agency_id, true)
  end
end
