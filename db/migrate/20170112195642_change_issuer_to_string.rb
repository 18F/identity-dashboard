class ChangeIssuerToString < ActiveRecord::Migration
  def change
    change_column :service_providers, :issuer, :string, null: false
  end
end
