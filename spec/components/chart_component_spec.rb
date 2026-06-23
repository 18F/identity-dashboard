# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChartComponent, type: :component do
  include ActionView::TestCase::Behavior

  let(:usage_data) do
    {
      'Newly Created Accounts' => rand(10..100),
      'Existing Accounts' => rand(100..1000),
    }
  end
  let(:title) { "Placeholder Title #{rand(10..1000)}" }

  it 'can render with provided values' do
    render = render_inline(described_class.new(
      title:,
      type: :column_chart,
      data: usage_data,
      options: { download: true },
    ))
    expect(render).to_not be_blank
    expect(render.text).to include(title)
    render_as_string = render.to_s
    expect(render_as_string).to include(usage_data.keys.first)
    expect(render_as_string).to include(usage_data.values.first.to_s)
    expect(render_as_string).to include(usage_data.keys.second)
    expect(render_as_string).to include(usage_data.values.second.to_s)
  end
end
