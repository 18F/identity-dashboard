class AddUsersAndApplications < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |tbl|
      tbl.uuid :uuid, null: false
      tbl.string :email, null: false
      tbl.string :first_name
      tbl.string :last_name
      tbl.timestamps
    end

    add_index :users, :uuid, unique: true
    add_index :users, :email, unique: true

    create_table :applications do |tbl|
      tbl.integer :user_id, null: false
      tbl.uuid :issuer, null: false
      tbl.string :name
      tbl.text :description
      tbl.text :metadata_url
      tbl.text :acs_url
      tbl.text :assertion_consumer_logout_service_url
      tbl.text :saml_client_cert
      tbl.integer :block_encryption, null: false, default: 1
      tbl.timestamps
    end

    add_index :applications, :issuer, unique: true
  end
end
