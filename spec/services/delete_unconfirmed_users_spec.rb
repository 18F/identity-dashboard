require 'rails_helper'

describe DeleteUnconfirmedUsers do
  describe '#call' do
    context 'when 1 account is deleted' do
      it 'logs/returns the number of deleted accounts' do
        expect(Rails.logger).to receive(:info).with(
          'Deleted unconfirmed users count=1',
        )

        User.create(
          email: 'user1@late.gov',
          created_at: 15.days.ago,
        )

        expect(described_class.call).to eq(1)
      end
    end

    context 'when multiple accounts are deleted' do
      it 'logs/returns the number of deleted accounts' do
        expect(Rails.logger).to receive(:info).with(
          'Deleted unconfirmed users count=2',
        )

        ['user1@late.gov', 'user2@late.gov'].each do |email|
          User.create(email:, created_at: 15.days.ago)
        end

        expect(described_class.call).to eq(2)
      end
    end

    context 'when no accounts are deleted' do
      it 'returns the count but does update the logs' do
        expect(Rails.logger).to_not receive(:info)
        expect(described_class.call).to eq(0)
      end
    end
  end
end
