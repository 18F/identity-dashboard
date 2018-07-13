class UuiDtoString < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :uuid, :string, null: false
  end
end
