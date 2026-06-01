# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TabComponent, type: :component do
  include ActionView::TestCase::Behavior

  let(:render) do
    render_inline(
      described_class.new(tab_data: [
                            { title: 'test 0',
                              id: 'zeroth-test',
                              content: render_inline('components/logo_banner'),
                              focusable: false },
                            { title: 'test 1',
                              id: 'first-test',
                              content: render_inline({
                                partial: 'components/step_progress',
                                locals: {
                                  steps: ['edit', 'index'],
                                  current_step_index: 0,
                                  localization_base: 'headings.service_providers',
                                },
                              }),
                              focusable: false },
                          ]),
    )
  end

  it 'displays a set of tabs' do
    expect(render.css('[role="tablist"]').count).to eq(1)
    list_items = render.css('[role="tab"]')
    expect(list_items.count).to eq(2)
  end

  it 'displays appropriate anchor links in tabs' do
    anchors = render.css('a.usa-tab__item')
    expect(anchors.count).to eq(2)
    strings = ['test 0', 'test 1']
    anchors.map(&:text).each_with_index do |str, index|
      expect(str).to include(strings[index])
    end
    expect(anchors.map { |a| a.attr('href') }).to eq(['#zeroth-test', '#first-test'])
  end
end
