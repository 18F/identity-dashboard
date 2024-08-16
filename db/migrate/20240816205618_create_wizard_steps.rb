class CreateWizardSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :wizard_steps do |t|
      t.references :user, null: false, foreign_key: true
      t.string :step_name
      t.json :data

      t.timestamps
    end
  end
end
