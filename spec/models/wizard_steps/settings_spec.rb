require 'rails_helper'
RSpec.describe WizardSteps::SettingsStep do
  let(:app_name) { 'Production config' }
  let(:description) { 'test with prod_config' }
  let(:friendly_name) { 'Friendly name' }
  let(:team) { create(:team) }
  let(:group_id) { team.id }
  let(:prod_config) { true }
  let(:wizard_form_data) do
    {
      app_name:,
      description:,
      friendly_name:,
      group_id:,
      prod_config:,
    }.as_json
  end
  let(:wizard_step) { create(:wizard_step, step_name: 'settings', wizard_form_data:) }

  subject { described_class.new(wizard_step) }

  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          app_name: '',
          description: '',
          friendly_name: '',
          group_id: nil,
          prod_config: false,
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "settings"' do
      expect(described_class.step_name).to eq 'settings'
    end
  end

  describe '#init' do
    it 'sets the wizard_step attribute' do
      expect(subject.instance_variable_get(:@wizard_step)).to eq wizard_step
    end
  end

  describe 'validations' do
    describe 'when app_name does not exist' do
      let(:app_name) { nil }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors.messages).to eq({ app_name: ["can't be blank"] })
      end
    end

    describe 'when description does not exist' do
      let(:description) { nil }

      it 'is valid' do
        expect(subject.valid?).to be true
      end
    end

    describe 'when friendly_name does not exist' do
      let(:friendly_name) { nil }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors.messages).to eq({ friendly_name: ["can't be blank"] })
      end
    end

    describe 'when group_id does not exist' do
      let(:group_id) { nil }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors.messages).to eq({ group_id: ["can't be blank", 'is invalid'] })
      end
    end

    describe 'when group does not exist' do
      let(:group_id) { 18 }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors.messages).to eq({ group_id: ['is invalid'] })
      end
    end

    describe 'when all attributes are present and valid' do
      it 'returns true' do
        expect(subject.valid?).to be true
      end
    end
  end

  describe '#production_ready?' do
    describe 'when prod_config to true' do
      it 'returns true' do
        expect(subject.production_ready?).to be true
      end
    end

    describe 'when prod_config is set to "true"' do
      let(:prod_config) { 'true' }

      it 'returns true' do
        expect(subject.production_ready?).to be true
      end
    end

    describe 'when prod_config is false' do
      let(:prod_config) { false }

      it 'returns false' do
        expect(subject.production_ready?).to be false
      end
    end
  end
end
