require 'rails_helper'

describe Reports::Fraud do
  let(:mock_data) do
    {
      'count_ssn_dob_deceased' => rand(1..1000),
      'count_suspicious_phone' => rand(1..1000),
      'count_inauthentic_doc' => rand(1..1000),
      # A valid key that is not a fraud key, so should get skipped over
      'count_preverified_users' => rand(1..1000),
    }
  end
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(mock_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  it '#total sums all and only fraud data' do
    expected_total = mock_data.values.sum - mock_data['count_preverified_users']
    expect(subject.total).to be(expected_total)
  end

  describe 'when numbers are nil' do
    let(:mock_data) do
      JSON.parse(Rails.root.join(
        'spec/fixtures/reports/6236/monthly/2025-08-01.json',
      ).read)['data']
    end

    it 'returns nil' do
      expect(subject.total).to be_nil
    end
  end
end
