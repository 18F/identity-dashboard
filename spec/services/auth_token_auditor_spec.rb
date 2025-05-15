require 'rails_helper'

describe AuthTokenAuditor do
  describe '.new' do
    it 'defaults to using the rails logger' do
      logger = described_class.new.logger
      expect(logger).to be(Rails.logger)
    end

    it 'allows injecting a logger' do
      expected_logger = object_double(Rails.logger)
      actual_logger = described_class.new(expected_logger).logger
      expect(actual_logger).to_not be(Rails.logger)
      expect(actual_logger).to be(expected_logger)
    end
  end

  context 'with some mock objects' do
    subject(:auditor_with_mock) { described_class.new(logger_double) }

    let(:logger_double) { object_double(Rails.logger) }
    # let(:controller_double) { object_double(AuthTokensController.new) }
    let(:controller_double) { AuthTokensController.new }
    let(:record_double) { build(:auth_token) }

    before do
      allow(logger_double).to receive(:info)
    end

    describe '#in_controller' do
      it 'logs an action' do
        current_user = build(:user)
        action_name = ['create', 'new'].sample
        request = ActionDispatch::Request.new({})
        expect(controller_double).to receive_messages(current_user:, action_name:, request:)
        expect(logger_double).to receive(:info).with(
          "#{described_class::EVENT_TAG}: User #{current_user.email} running " \
          "#{AuthTokensController}##{action_name} via http://:",
        )
        auditor_with_mock.in_controller(controller_double)
      end
    end

    describe '#record_change' do
      it 'logs a change' do
        new_record = build(:auth_token)
        expect(logger_double).to receive(:info).with(
          "#{described_class::EVENT_TAG}: Saved changes for #{new_record.user.email}",
        )
        auditor_with_mock.record_change(new_record)
      end
    end
  end
end
