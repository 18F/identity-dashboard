class CreateBanners < ActiveRecord::Migration[7.1]
  def change
    create_table :banners do |t|
      t.text :message
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
