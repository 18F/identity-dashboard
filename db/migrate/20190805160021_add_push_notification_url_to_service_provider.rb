# Add push_notification_url to service_provider
class AddPushNotificationUrlToServiceProvider < ActiveRecord::Migration[5.1]
  def change
    add_column :service_providers, :push_notification_url, :string
  end
end
