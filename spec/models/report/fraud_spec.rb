require 'rails_helper'

describe Report::Fraud do
  let(:test_data) do
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
    allow(mock).to receive(:data).and_return(test_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  it '#total sums all and only fraud data' do
    expected_total = test_data.values.sum - test_data['count_preverified_users']
    expect(subject.total).to be(expected_total)
  end

  it 'can return #chart options with correct data' do
    expect(subject.chart).to eq({
      type: :bar_chart,
      data: [
        ['Rejected for Invalid SSN / DOB, or Deceased', test_data['count_ssn_dob_deceased']],
        ['Suspicious Phone', test_data['count_suspicious_phone']],
        ['Inauthentic Doc.', test_data['count_inauthentic_doc']],
      ],
      title: 'Fraudsters Blocks',
      options: { subtitle: 'Users blocked per outcome type' },
    })
  end

  describe 'when numbers are nil' do
    let(:test_data) do
      JSON.parse(Rails.root.join(
        'spec/fixtures/reports/6236/monthly/2025-08-01.json',
      ).read)['data']
    end

    it 'returns nil' do
      expect(subject.total).to be_nil
    end

    it 'has a #chart with empty data' do
      expect(subject.chart).to eq({
        type: :bar_chart,
        data: [],
        title: 'Fraudsters Blocks',
        options: { subtitle: 'Users blocked per outcome type' },
      })
    end
  end
end
