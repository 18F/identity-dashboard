class AddAllowPromptLoginToServiceProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :service_providers, :allow_prompt_login, :boolean, default: false
  end
end
