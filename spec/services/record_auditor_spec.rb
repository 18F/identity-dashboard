require 'rails_helper'

describe RecordAuditor do
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

  context 'with some mock objects' do
    subject(:auditor_with_mock) { described_class.new(
      controller: fake_controller,
      logger: logger_double,
    ) }

    let(:logger_double) { instance_double(EventLogger) }

    before do
      allow(logger_double).to receive(:record_save)
      allow(EventLogger).to receive(:new).and_return(logger_double)
    end

    describe '#record_change' do
      it 'logs record changes' do
        fake_record = FakeRecord.new
        described_class.new(controller: fake_controller).record_change(fake_record)

        expect(logger_double).to have_received(:record_save)
      end
    end
  end
end
