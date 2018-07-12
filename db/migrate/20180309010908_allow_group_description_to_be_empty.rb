class AllowGroupDescriptionToBeEmpty < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:groups, :description, true)
  end
end
