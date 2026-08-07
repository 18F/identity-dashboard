require 'rails_helper'
RSpec.describe WizardSteps::IntroStep do
  describe '.fields' do
    it 'returns an empty hash' do
      expect(described_class.fields).to eq({})
    end
  end

  describe '.step_name' do
    it 'returns "intro"' do
      expect(described_class.step_name).to eq 'intro'
    end
  end
end
