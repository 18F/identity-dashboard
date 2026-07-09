require 'rails_helper'

describe Report::Usage do
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(test_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  describe 'with valid data' do
    let(:test_data) do
      {
        'count_newly_created_accounts' => rand(1..1000),
        'count_auth_successful' => rand(1..1000),
        # A valid key that does not count toward usage
        'count_inauthentic_doc' => rand(1..1000),
      }
    end

    it 'returns a #total' do
      expect(subject.total).to eq(test_data['count_newly_created_accounts'])
    end

    it 'returns #succesful_auths' do
      expect(subject.successful_auths).to eq(test_data['count_auth_successful'])
    end

    it 'returns a #chart' do
      expect(subject.chart).to eq({
        type: :column_chart,
        data: [
          [I18n.t('reports.count_newly_created_accounts'),
           test_data['count_newly_created_accounts']],
        ],
        title: 'All Active Users',
        options: {
          subtitle: 'Unique users who accessed a service',
          description: 'New accounts reflect account creation during this window. ' \
                          'Existing accounts reflect accounts created ahead of this window.',
        },
      })
    end
  end

  describe 'with nil data' do
    let(:test_data) do
      {
        'count_newly_created_accounts' => nil,
        'count_existing_accounts' => nil,
        'count_auth_successful' => nil,
        # A valid key that does not count toward usage
        'count_inauthentic_doc' => rand(1..1000),
      }
    end

    it 'returns a nil #total' do
      expect(subject.total).to be_nil
    end

    it 'returns nil #succesful_auths' do
      expect(subject.total).to be_nil
    end

    it 'returns an empty #chart' do
      expect(subject.chart[:data]).to eq([])
    end
  end

  describe 'with zeroed data' do
    let(:test_data) do
      {
        'count_newly_created_accounts' => 0,
        'count_existing_accounts' => 0,
        'count_auth_successful' => 0,
        # A valid key that does not count toward usage
        'count_inauthentic_doc' => rand(0..1000),
      }
    end

    it 'returns a zero #total' do
      expect(subject.total).to be(0)
    end

    it 'returns zero #succesful_auths' do
      expect(subject.total).to be(0)
    end

    it 'returns a zeroed #chart' do
      expect(subject.chart[:data]).to eq(
        [
          [I18n.t('reports.count_newly_created_accounts'), 0],
          [I18n.t('reports.count_existing_accounts'), 0],
        ],
      )
    end
  end
end
