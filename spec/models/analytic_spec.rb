require 'rails_helper'

RSpec.describe Analytic, type: :model do
  let(:analytic) { Analytic.new }
  let(:service_provider) {}
  let(:period_start) {}
  let(:report_data) {}

  describe '#uuid' do
    before do
      analytic.config = service_provider
      analytic.date = '2025-12-01'
      analytic.data = {}
    end

    it 'returns the UUID of the related config' do
      service_provider = create(:service_provider)

      expect(analytic.uuid).to eq(service_provider.uuid)
    end

    it 'returns nil instead of an error when the config is not present' do
      expect(analytic.uuid).to eq(nil)
    end
  end

  describe '#valid?' do
    before do
      analytic.config = service_provider
      analytic.date = period_start
      analytic.data = report_data
    end

    it 'calls #is_valid?' do
      allow(analytic).to receive(:is_valid?).and_return(false)
      analytic.valid?

      expect(analytic).to have_received(:is_valid?).once
    end
  end
end
