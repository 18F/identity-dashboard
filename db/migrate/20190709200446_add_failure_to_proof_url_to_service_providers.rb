class AddFailureToProofUrlToServiceProviders < ActiveRecord::Migration[5.1]
  def change
    add_column :service_providers, :failure_to_proof_url, :string
  end
end
