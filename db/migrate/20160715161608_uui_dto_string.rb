class UuiDtoString < ActiveRecord::Migration
  def change
    change_column :users, :uuid, :string, null: false
  end
end
