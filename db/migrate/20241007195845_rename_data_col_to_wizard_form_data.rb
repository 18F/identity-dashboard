class RenameDataColToWizardFormData < ActiveRecord::Migration[7.1]
  def change
    rename_column :wizard_steps, :data, :wizard_form_data
  end
end
