class AddEmailNameIdFormatToServiceProviders < ActiveRecord::Migration[6.1]
  def change
    add_column :service_providers, :email_nameid_format_allowed, :boolean, default: false
  end
end
