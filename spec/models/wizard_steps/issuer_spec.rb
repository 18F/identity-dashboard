require 'rails_helper'
RSpec.describe WizardSteps::IssuerStep do
  let(:issuer) { 'brand-new-issuer' }
  let(:wizard_form_data) do
    {
      issuer:,
    }.as_json
  end
  let(:wizard_step) { create(:wizard_step, step_name: 'issuer', wizard_form_data:) }

  subject { described_class.new(wizard_step) }
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          issuer: '',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "issuer"' do
      expect(described_class.step_name).to eq 'issuer'
    end
  end

  describe '#init' do
    it 'sets the wizard_step attribute' do
      expect(subject.instance_variable_get(:@wizard_step)).to eq wizard_step
    end
  end

  describe 'validations' do
    describe 'when issuer does not exist' do
      let(:issuer) { nil }

      it 'is invalid' do
        expect(subject.valid?).to be false
        expect(subject.errors.messages).to eq({ issuer: ["can't be blank", 'is invalid'] })
      end
    end
    describe 'when issuer does not meet issuer format' do
      let(:issuer) { 'brand new issuer with whitespace' }

      it 'is invalid' do
        expect(subject.valid?).to be false
        expect(subject.errors.messages).to eq({ issuer: ['is invalid'] })
      end
    end

    describe 'when issuer string is not unique' do
      let!(:sp) { create(:service_provider) }
      let(:issuer) { sp.issuer }

      it 'is invalid' do
        expect(subject.valid?).to be false
        expect(subject.errors.messages).to eq({ issuer: ['already in use'] })
      end
    end

    describe 'when user is editing service provider' do
      let(:user) { create(:user, :with_teams) }
      let(:sp) { create(:service_provider, issuer:, team: user.teams.first) }
      let(:hidden_form_data) { { service_provider_id: sp.id }.as_json }
      let(:wizard_step) { create(:wizard_step, step_name: 'issuer', user:, wizard_form_data:) }

      subject { described_class.new(wizard_step) }

      before do
        # create the hidden step associated with the same user
        create(:wizard_step, step_name: 'hidden', user:, wizard_form_data: hidden_form_data)
      end

      it 'is valid' do
        expect(subject.valid?).to be true
      end
    end
  end
end
