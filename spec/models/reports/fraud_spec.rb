require 'rails_helper'

describe Reports::Usage do
  let(:mock_data) do
    {}
  end
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(mock_data)
  end

  subject { described_class.new(mock_reports) }

  it 'returns fraud data' do
    expect(fraud_total)
  end

  describe 'when numbers are nil' do
    let(:mock_data) do
      JSON.parse(Rails.root.join('spec/fixtures/reports/6236/monthly/2025-08-01.json'))['data']
    end

    it 'returns nil' do
      expect(subject.fraud_total).to be_nil
    end
  end
end
