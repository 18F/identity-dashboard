# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TabComponent, type: :component do
  include ActionView::TestCase::Behavior

  let(:render) do
    render_inline(
      described_class.new(tabs: [
        { name: 'test 0', anchor: 'zeroth-test' },
        { name: 'test 1', anchor: 'first-test' },
      ]),
    )
  end

  it 'displays an unordered list of tabs' do
    expect(render.css('ul').count).to eq(1)
    list_items = render.css('li')
    expect(list_items.count).to eq(2)
  end

  it 'displays appropriate anchor links in tabs' do
    anchors = render.css('li a')
    expect(anchors.count).to eq(2)
    expect(anchors.map(&:text)).to eq(['test 0', 'test 1'])
    expect(anchors.map { |a| a.attr('href') }).to eq(['#zeroth-test', '#first-test'])
  end
end
