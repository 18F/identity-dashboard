class CreateAirtable < ActiveRecord::Migration[7.2]
  def change
    create_table :airtables do |t|
      t.integer :user_id
      t.string :token
      t.datetime :token_expiration
      t.string :refresh_token
      t.datetime :refresh_token_expiration
      t.string :state
      t.string :code_verifier

      t.timestamps
    end
  end
end
