require 'rails_helper'
RSpec.describe WizardSteps::AuthenticationStep do
  let(:user) { create(:user) }
  let(:ial) { '1' }
  let(:default_aal) { 0 }
  let(:attribute_bundle) { [] }
  let(:identity_protocol) { 'openid_connect_private_key_jwt' }
  let(:wizard_form_data) do
    {
      attribute_bundle:,
      default_aal:,
      ial:,
    }.as_json
  end
  let(:wizard_step) do
    create(:wizard_step, user:, step_name: 'authentication', wizard_form_data:)
  end

  subject { described_class.new(wizard_step) }

  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          attribute_bundle: [],
          default_aal: 0,
          ial: '1',
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "authentication"' do
      expect(described_class.step_name).to eq 'authentication'
    end
  end

  describe '#init' do
    it 'sets the wizard_step attribute' do
      expect(subject.instance_variable_get(:@wizard_step)).to eq wizard_step
    end
  end

  describe 'validations' do
    describe 'when all attributes are present and valid' do
      it 'returns true' do
        expect(subject.valid?).to be(true)
      end
    end

    describe 'when ial is set to 2' do
      let(:ial) { '2' }

      it 'is valid' do
        expect(subject.valid?).to be true
      end

      describe 'when the protocol is SAML' do
        before do
          create(:wizard_step, user:, step_name: 'protocol', wizard_form_data: {
            identity_protocol: 'saml',
          })
        end

        describe 'when the attribute bundle is empty' do
          it 'is not valid' do
            expect(subject.valid?).to be false
            expect(subject.errors[:attribute_bundle]).to eq(['Attribute bundle cannot be empty'])
          end
        end
      end

      describe 'when the protocol is OIDC' do
        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end
    end

    describe 'when ial is set to 1' do
      it 'is valid' do
        expect(subject.valid?).to be true
      end
    end

    describe 'when ial is set to an invalid value' do
      let(:ial) { '4' }

      it 'is not valid' do
        expect(subject.valid?).to be false
      end
    end

    describe 'when the attribute bundle contains an unknown attribute' do
      let(:attribute_bundle) { %w[gibberish] }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors[:attribute_bundle]).to eq(['Contains invalid attributes'])
      end
    end

    describe 'when the attribute bundle contains invalid attributes' do
      let(:attribute_bundle) { %w[email first_name] }

      it 'is not valid' do
        expect(subject.valid?).to be false
        expect(subject.errors[:attribute_bundle]).to eq(
          ['Contains ial 2 attributes when ial 1 is selected'],
        )
      end
    end
  end

  describe '#remove_blank_attributes' do
    let(:attribute_bundle) { ['', 'email'] }

    it 'removes blank entries from the attribute bundle' do
      subject.remove_blank_attributes

      expect(wizard_step.wizard_form_data['attribute_bundle']).to eq(%w[email])
    end

    it 'runs before validation' do
      expect(wizard_step.wizard_form_data['attribute_bundle']).to eq(attribute_bundle)
      expect(subject.valid?).to be(true)
      expect(wizard_step.wizard_form_data['attribute_bundle']).to eq(%w[email])
    end

    describe 'when the attribute bundle is empty' do
      let(:attribute_bundle) { [] }

      it 'leaves the attribute bundle alone' do
        subject.remove_blank_attributes

        expect(wizard_step.wizard_form_data['attribute_bundle']).to eq([])
      end
    end
  end
end
