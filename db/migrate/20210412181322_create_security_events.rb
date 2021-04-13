class CreateSecurityEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :security_events do |t|
      t.integer :user_id, null: false
      t.string :uuid
      t.timestamp :issued_at
      t.string :event_type
      t.text :raw_event

      t.timestamps

      t.index :user_id
      t.index :uuid
      t.index :issued_at
    end
  end
end
