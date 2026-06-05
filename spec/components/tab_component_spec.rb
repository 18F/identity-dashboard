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

  context '#add_tab' do
    let(:tab) do
      described_class.new(tab_data: [], opts: { class: 'test' })
    end
    let(:test_data) do
      { title: 'new', id: "id_#{rand(10..1000)}", content: 'test' }
    end

    it 'adds an object to the tab_data array' do
      tab.add_tab(
        title: test_data[:title],
        id: test_data[:id],
        content: test_data[:content],
      )

      expect(tab.tab_data[-1]).to eq(test_data)
    end
  end
end
