class RemoveServiceProviderAgencyNullConstraint < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:service_providers, :agency_id, true)
  end
end
