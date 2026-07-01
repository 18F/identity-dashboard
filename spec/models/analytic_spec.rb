require 'rails_helper'

RSpec.describe Analytic do
  let(:analytic) { Analytic.new }
  let(:invalid_service_provider) { nil }
  let(:valid_service_provider) { build(:service_provider, :ready_to_activate) }
  let(:invalid_period_start) { nil }
  let(:valid_period_start) { '2025-12-01' }
  let(:report_data) { nil }

  describe '#uuid' do
    before do
      analytic.date = '2025-12-01'
    end

    it 'returns the UUID of the related config' do
      analytic.config = valid_service_provider
      expect(analytic.uuid).to eq(valid_service_provider.uuid)
    end

    it 'returns nil instead of an error when the config is not present' do
      analytic.config = invalid_service_provider
      expect(analytic.uuid).to eq(nil)
    end
  end

  describe '#valid?' do
    it 'returns true when all checks pass' do
      analytic.config = valid_service_provider
      analytic.date = valid_period_start

      expect(analytic.valid?).to be_truthy
    end

    it 'only has one error when the config is invalid' do
      analytic.config = valid_service_provider
      analytic.config = invalid_service_provider

      expect(analytic.valid?).to be_falsey
      expect(analytic.errors.count).to be(1)
      expect(analytic.errors.full_messages).to eq(
        [I18n.t('reports.errors.generic')],
      )
    end

    it 'only has one error when the date is invalid' do
      analytic.config = invalid_service_provider
      analytic.config = valid_service_provider

      expect(analytic.valid?).to be_falsey
      expect(analytic.errors.count).to be(1)
      expect(analytic.errors.full_messages).to eq(['Date is invalid'])
    end
  end
end
