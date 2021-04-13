require 'rails_helper'

RSpec.describe 'security_events/table.html.erb' do
  subject(:render_partial) do
    render partial: 'security_events/table',
          locals: {
            security_events: security_events,
            show_user: show_user,
            prev_page: prev_page,
            next_page: next_page,
          }
  end

  let(:user) { create(:user) }
  let(:security_events) do
    2.times.map { create(:security_event, user: user) }
  end
  let(:show_user) { false }
  let(:prev_page) { nil }
  let(:next_page) { nil }

  it 'renders a table of security events' do
    render_partial

    rows = Nokogiri::HTML(rendered).css('tbody tr')
    expect(rows.size).to eq(2)

    expect(rows.map { |r| r.css('td')[1].text.strip }).to eq(security_events.map(&:uuid))
  end

  context 'with show_user: false' do
    let(:show_user) { false }

    it 'does not have an email column' do
      render_partial

      expect(rendered).to_not have_selector('th[scope=col]', text: 'User')
    end
  end

  context 'with show_user: true' do
    let(:show_user) { true }

    it 'adds an email column' do
      render_partial

      expect(rendered).to have_selector('th[scope=col]', text: 'User')
      expect(rendered).to include(user.email)
    end
  end

  context 'on the first page' do
    let(:next_page) { '?page=2' }

    it 'has a disabled previous link and an active next link' do
      render_partial

      expect(rendered).to have_selector('span[class=text-base-light]', text: 'Previous')
      expect(rendered).to have_selector("a[href='#{next_page}']", text: 'Next')
    end
  end

  context 'in a middle page' do
    let(:prev_page) { '?page=1' }
    let(:next_page) { '?page=3' }

    it 'has active previous and next links' do
      render_partial

      expect(rendered).to have_selector("a[href='#{prev_page}']", text: 'Previous')
      expect(rendered).to have_selector("a[href='#{next_page}']", text: 'Next')
    end
  end

  context 'on the last page' do
    let(:prev_page) { '?page=2' }

    it 'has active a disabled next link and an active previous link' do
      render_partial

      expect(rendered).to have_selector("a[href='#{prev_page}']", text: 'Previous')
      expect(rendered).to have_selector('span[class=text-base-light]', text: 'Next')
    end
  end
end
