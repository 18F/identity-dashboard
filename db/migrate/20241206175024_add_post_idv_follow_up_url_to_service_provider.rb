class AddPostIdvFollowUpUrlToServiceProvider < ActiveRecord::Migration[7.1]
  def change
    add_column :service_providers, :post_idv_follow_up_url, :string
  end
end
