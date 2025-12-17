require 'rails_helper'

describe PaginationHelper do
  describe '#pagination_visible_pages' do
    let(:overflow) { PaginationHelper::OVERFLOW }

    context 'when total_pages is 1 or less' do
      it 'returns empty array for 1 page' do
        result = pagination_visible_pages(current_page: 1, total_pages: 1)
        expect(result).to eq([])
      end

      it 'returns empty array for 0 pages' do
        result = pagination_visible_pages(current_page: 1, total_pages: 0)
        expect(result).to eq([])
      end
    end

    context 'when total_pages is 7 or less' do
      it 'returns all pages for 3 pages' do
        result = pagination_visible_pages(current_page: 2, total_pages: 3)
        expect(result).to eq([1, 2, 3])
      end

      it 'returns all pages for 7 pages' do
        result = pagination_visible_pages(current_page: 4, total_pages: 7)
        expect(result).to eq([1, 2, 3, 4, 5, 6, 7])
      end
    end

    context 'when current_page is near the beginning (1-4)' do
      let(:total_pages) { 20 }

      it 'shows pages 1-5, overflow, and last page when on page 1' do
        result = pagination_visible_pages(current_page: 1, total_pages: total_pages)
        expect(result).to eq([1, 2, 3, 4, 5, overflow, 20])
      end

      it 'shows pages 1-5, overflow, and last page when on page 4' do
        result = pagination_visible_pages(current_page: 4, total_pages: total_pages)
        expect(result).to eq([1, 2, 3, 4, 5, overflow, 20])
      end
    end

    context 'when current_page is near the end' do
      let(:total_pages) { 20 }

      it 'shows page 1, overflow, and last 5 pages when on last page' do
        result = pagination_visible_pages(current_page: 20, total_pages: total_pages)
        expect(result).to eq([1, overflow, 16, 17, 18, 19, 20])
      end

      it 'shows page 1, overflow, and last 5 pages when on page total_pages - 3' do
        result = pagination_visible_pages(current_page: 17, total_pages: total_pages)
        expect(result).to eq([1, overflow, 16, 17, 18, 19, 20])
      end
    end

    context 'when current_page is in the middle' do
      let(:total_pages) { 20 }

      it 'shows page 1, overflow, current-1, current, current+1, overflow, last page' do
        result = pagination_visible_pages(current_page: 10, total_pages: total_pages)
        expect(result).to eq([1, overflow, 9, 10, 11, overflow, 20])
      end

      it 'handles page 5 as middle (just past the beginning threshold)' do
        result = pagination_visible_pages(current_page: 5, total_pages: total_pages)
        expect(result).to eq([1, overflow, 4, 5, 6, overflow, 20])
      end

      it 'handles page 16 as middle (just before the end threshold)' do
        result = pagination_visible_pages(current_page: 16, total_pages: total_pages)
        expect(result).to eq([1, overflow, 15, 16, 17, overflow, 20])
      end
    end

    context 'with large page counts' do
      it 'handles 100 pages correctly' do
        result = pagination_visible_pages(current_page: 50, total_pages: 100)
        expect(result).to eq([1, overflow, 49, 50, 51, overflow, 100])
      end

      it 'handles 1000 pages correctly' do
        result = pagination_visible_pages(current_page: 500, total_pages: 1000)
        expect(result).to eq([1, overflow, 499, 500, 501, overflow, 1000])
      end
    end
  end
end
