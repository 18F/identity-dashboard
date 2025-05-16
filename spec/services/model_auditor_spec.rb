require 'rails_helper'

describe ModelAuditor do
  let(:fake_controller) { FakeController.new }

  describe '.new' do
    it 'defaults to using a new EventLogger' do
      logger = described_class.new(controller: fake_controller).logger
      expect(logger).to be_a(EventLogger)
    end

    it 'allows injecting a logger' do
      expected_logger = object_double(Rails.logger)
      actual_logger = described_class.new(
        controller: fake_controller,
        logger: expected_logger,
      ).logger
      expect(actual_logger).to_not be_a(EventLogger)
      expect(actual_logger).to be(expected_logger)
    end
  end
end
