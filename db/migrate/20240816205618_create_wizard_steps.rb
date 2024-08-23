class CreateWizardSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :wizard_steps do |t|
      t.references :user, null: false, foreign_key: true
      t.string :step_name, null: false
      t.json :data

      t.timestamps

      t.index [:user_id, :step_name], unique: true
    end
  end
end
