class AllowGroupDescriptionToBeEmpty < ActiveRecord::Migration
  def change
    change_column_null(:groups, :description, true)
  end
end
