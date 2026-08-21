require 'rails_helper'

RSpec.describe AnalyticsReportStorage::Disk do
  describe '#fetch' do
    it 'pulls the expected file' do
      test_key = '4388/monthly/2025-12-01.json'
      expected_data = Rails.root.join(described_class.default_config[:root], test_key).read

      expect(described_class.new.fetch(test_key)).to eq(expected_data)
    end
  end
end
