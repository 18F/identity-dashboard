# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WizardFieldsetComponent, type: :component do
  include ActionView::TestCase::Behavior

  let(:wizard_step) { build(:wizard_step, step_name: 'protocol') }
  let(:form) { SimpleForm::FormBuilder.new(:wizard_step, wizard_step, view, {}) }
  let(:protocol_inputs) do
    { 'OpenID Connect JWT' => :openid_connect_private_key_jwt, 'SAML' => :saml }
  end

  it 'looks for a description translation key ending in `_html` by default' do
    render = render_inline(described_class.new(
      form:, input_type: 'radio', model_method: 'identity_protocol', protocol_inputs:,
    ),
                          )
    expect(render.text).to include('OpenID Connect JWT')
    expect(render.text).to include('SAML')
    expect(render.to_s).to include(t('service_provider_form.identity_protocol_html'))
  end

  it 'can use an arbitrary description' do
    render = render_inline(described_class.new(
      form:, input_type: 'radio', model_method: 'identity_protocol', protocol_inputs:,
      description_key: 'public_certificate'
    ),
                          )
    expect(render.text).to include('OpenID Connect JWT')
    expect(render.text).to include('SAML')
    expect(render.to_s).to_not include(t('service_provider_form.identity_protocol_html'))
    expect(render.to_s).to include(t('service_provider_form.public_certificate'))
  end
end
