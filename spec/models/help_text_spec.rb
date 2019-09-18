require 'rails_helper'

RSpec.describe HelpText, type: :model do
  describe 'Associations' do
    it { should belong_to(:service_provider) }
  end

  describe 'Validations' do
    it { should validate_uniqueness_of(:service_provider_id) }

    it 'accepts a correctly formatted issuer' do
      unsanitary_help_text = create(
          :help_text,
          sign_in: {en: '<script>unsanitary script</script>'},
          service_provider: create(:service_provider)
      )
      expect(unsanitary_help_text.sign_in["en"]).to eq 'unsanitary script'
    end

  end
end
