class ChangeIssuerToString < ActiveRecord::Migration[4.2]
  def change
    change_column :service_providers, :issuer, :string, null: false
  end
end
