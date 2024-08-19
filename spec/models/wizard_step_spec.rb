require 'rails_helper'

RSpec.describe WizardStep, type: :model do
  # Substitute for the method that exists in controllers
  def policy_scope(user)
    Pundit.policy_scope(user, WizardStep)
  end

  # Skip step 0 as it currently has no form data
  let(:random_form_step) { WizardStep::STEPS[1..-1].sample}

  let(:first_user) {create(:user)}

  describe '#find_or_intialize' do
    context 'with nothing relevant in the database' do
      it 'populates data defaults' do
        scoped_model = policy_scope(first_user).find_or_initialize_by(step_name: random_form_step)
        expect(scoped_model.data).to eq(WizardStep::STEP_DATA[random_form_step].fields)
      end
    end
  end

  describe 'dynamic form properites' do
    it 'populates all properties for all steps' do
      WizardStep::STEPS.each do |step_name|
        subject = WizardStep.new(step_name: step_name)
        WizardStep::STEP_DATA[step_name].fields.keys.each do |field_name|
          expect(subject.send field_name).to eq(WizardStep::STEP_DATA[step_name].fields[field_name])
        end
      end
    end

    it 'pulls data back out' do
      expected_name = "Test name #{rand(1..10000)}"
      subject = WizardStep.new(step_name: 'settings')
      subject.data = {friendly_name: expected_name}
      expect(subject.friendly_name).to eq(expected_name)
    end
  end
end
