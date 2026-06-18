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

      allow(analytic).to receive(:config_valid?).and_return(true)
      allow(analytic).to receive(:valid_date?).and_return(true)
      allow(analytic).to receive(:data_valid?).and_return(true)
    end

    it 'calls #is_valid? when #valid? is called' do
      allow(analytic).to receive(:is_valid?).and_return(false)
      analytic.valid?

      expect(analytic).to have_received(:is_valid?).once
    end

    it 'returns true when all checks pass' do
      expect(analytic.is_valid?).to be_truthy
    end

    it 'makes minimal checks when the config is invalid' do
      allow(analytic).to receive(:config_valid?).and_return(false)

      expect(analytic.is_valid?).to be_falsey

      expect(analytic).to have_received(:config_valid?).once
      expect(analytic).to_not have_received(:valid_date?)
      expect(analytic).to_not have_received(:data_valid?)
    end

    it 'makes minimal checks when the date is invalid' do
      allow(analytic).to receive(:valid_date?).and_return(false)

      expect(analytic.is_valid?).to be_falsey

      expect(analytic).to have_received(:config_valid?).once
      expect(analytic).to have_received(:valid_date?).once
      expect(analytic).to_not have_received(:data_valid?)
    end

    it 'makes correct checks when the data is invalid' do
      allow(analytic).to receive(:data_valid?).and_return(false)

      expect(analytic.is_valid?).to be_falsey

      expect(analytic).to have_received(:config_valid?).once
      expect(analytic).to have_received(:valid_date?).once
      expect(analytic).to have_received(:data_valid?).once
    end
  end
end
