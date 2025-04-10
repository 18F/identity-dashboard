# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RadioCollectionComponent, type: :component do
  include ActionView::TestCase::Behavior

  let(:membership) { create(:user_team, role_name: Role::ACTIVE_ROLES_NAMES.keys.sample) }
  let(:form) { SimpleForm::FormBuilder.new(:user_team, membership, view, {}) }
  let(:random_id) { "id_#{rand(10..1000)}" }
  let(:inputs) { Role::ACTIVE_ROLES_NAMES.invert }

  it 'displays reasonable options with correct default' do
    render = render_inline(described_class.new(
      form: form,
      model_method: :role_name,
      inputs: inputs,
      describedby: random_id,
    ))
    list_items = render.css('li')
    expect(list_items.count).to eq(inputs.count)
    expect(list_items.map(&:text)).to eq(inputs.keys)
    radio_buttons = list_items.css('input')
    radio_button_values = radio_buttons.map { |button| button.attribute('value') }
    expect(radio_button_values.map(&:to_s)).to eq(inputs.values.map(&:to_s))
    selected_buttons = radio_buttons.css('[checked]')
    expect(selected_buttons.count).to be 1
    expect(selected_buttons.attribute('value').to_s).to eq(membership.role_name)
  end

  it 'allows for additional descriptions' do
    render = render_inline(described_class.new(
      form: form,
      model_method: :role_name,
      inputs: inputs,
      describedby: random_id,
      additional_descriptions: true,
    ))
    list_items = render.css('li')
    expect(list_items.count).to eq(inputs.count)
    extended_descriptions = inputs.map do |(name, value)|
      "#{name} #{I18n.t("user_teams.#{value}_description")}"
    end
    expect(list_items.map(&:text)).to eq(extended_descriptions)
  end
end
