require 'rails_helper'

describe CleanUsersService do
  describe '#call' do
    context 'when 1 account is deleted' do
      it 'logs the number of deleted accounts' do
        expect(Rails.logger).to receive(:info).with(
          'Deleted 1 unauthenticated account'
        )

        User.create(
          email: 'user1@late.gov',
          created_at: 15.days.ago
        )

        described_class.call
      end
    end

    context 'when multiple accounts are deleted' do
      it 'logs the number of deleted accounts' do
        expect(Rails.logger).to receive(:info).with(
          'Deleted 2 unauthenticated accounts'
        )

        ['user1@late.gov', 'user2@late.gov'].each do |email|
          User.create(email: email, created_at: 15.days.ago)
        end

        described_class.call
      end
    end

    context 'when no accounts are deleted' do
      it 'does not log the number of deleted accounts' do
        expect(Rails.logger).to_not receive(:info)
        described_class.call
      end
    end
  end
end
