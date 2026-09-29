require 'rails_helper'
RSpec.describe WizardSteps::ProtocolStep do
  let(:identity_protocol) { 'openid_connect_private_key_jwt' }
  let(:wizard_form_data) { { identity_protocol: }.as_json }
  let(:wizard_step) { create(:wizard_step, step_name: 'protocol', wizard_form_data:) }

  subject { described_class.new(wizard_step) }
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          identity_protocol:,
        },
      )
    end
  end
  describe '.fields' do
    it 'returns the expected fields' do
      expect(described_class.fields).to eq(
        {
          identity_protocol: ServiceProvider.identity_protocols.keys.first,
        },
      )
    end
  end

  describe '.step_name' do
    it 'returns "protocol"' do
      expect(described_class.step_name).to eq 'protocol'
    end
  end

  describe '#saml?' do
    describe 'when identity_protocol is openid_connect_private_key_jwt' do
      it 'is false' do
        expect(subject.saml?).to be false
      end
    end

    describe 'when identity_protocol is openid_connect_pkce' do
      let(:identity_protocol) { 'openid_connect_pkce' }

      it 'is false' do
        expect(subject.saml?).to be false
      end
    end

    describe 'when identity_protocol is saml' do
      let(:identity_protocol) { 'saml' }

      it 'is true' do
        expect(subject.saml?).to be true
      end
    end
  end
end
