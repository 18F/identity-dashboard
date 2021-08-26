class AddSignedResponseMessageRequestToServiceProvider < ActiveRecord::Migration[6.1]
  def change
    add_column :service_providers, :signed_response_message_requested, :boolean, default: false
  end
end
