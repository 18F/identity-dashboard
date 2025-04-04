require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#navigation_link_to' do
    let(:current_page) { true }

    before do
      allow(self).to receive(:current_page?).with('/current').and_return current_page
    end

    describe 'it is the current page' do
      it 'returns the passed in classes along with usa-current' do
        result = navigation_link_to('Current', '/current')
        link = '<a class="usa-current usa-nav__link" href="/current">Current</a>'

        expect(result).to eq link
      end
    end

    describe 'it is not the current page' do
      let(:current_page) { false }

      it 'returns just the passed in classes' do
        result = navigation_link_to('Current', '/current')
        link = '<a class="usa-nav__link" href="/current">Current</a>'

        expect(result).to eq link
      end
    end

  end
end
