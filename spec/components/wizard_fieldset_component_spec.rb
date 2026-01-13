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
    render = render_inline(
      described_class.new(
        form: form, input_type: 'radio', param_name: 'identity_protocol', inputs: protocol_inputs,
      ),
    )
    expect(render.text).to include('OpenID Connect JWT')
    expect(render.text).to include('SAML')

    # Need to compare like with like or otherwise this test may fail for unimportant reasons
    expected_html = '<p class="usa-hint">' +
                    t('service_provider_form.identity_protocol_html') +
                    '</p>'
    expected_html = Nokogiri.parse(expected_html).children
    expect(render.to_s).to include(expected_html.to_s)
  end

  it 'can use an arbitrary description' do
    render = render_inline(
      described_class.new(form: form,
                          input_type: 'radio',
                          param_name: 'identity_protocol',
                          inputs: protocol_inputs,
                          description_key: 'certificate'),
    )
    expect(render.text).to include('OpenID Connect JWT')
    expect(render.text).to include('SAML')

    # Need to compare like with like or otherwise this test may fail for unimportant reasons
    default_html = '<p class="usa-hint">' +
                   t('service_provider_form.identity_protocol_html') +
                   '</p>'
    default_html = Nokogiri.parse(default_html).children
    override_html = '<p class="usa-hint">' +
                    t('service_provider_form.certificate') +
                    '</p>'
    override_html = Nokogiri.parse(override_html).children
    expect(render.to_s).to_not include(default_html.to_s)
    expect(render.to_s).to include(override_html.to_s)
  end
end
