require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#classes' do
    let(:current_page) { true }
    before do
      allow(self).to receive(:current_page?).with('/current').and_return current_page
    end

    describe 'it is the current page' do
      it 'returns the passed in classes along with usa-current' do
        result = classes('/current', 'some classes')
        expect(result).to eq 'some classes usa-current'
      end
    end

    describe 'it is not the current page' do
      let(:current_page) { false }

      it 'returns just the passed in classes' do
        result = classes('/current', 'some classes')
        expect(result).to eq 'some classes'
      end
    end

  end
end
