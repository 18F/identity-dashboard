require 'rails_helper'

describe ServiceProviderForm do
  let(:current_user) { create(:user, :partner_admin) }

  context 'with a valid, built-out service provder' do
    let(:log_mock) do
      mock = instance_double(EventLogger)
      allow(mock).to receive(:sp_errors).never
      mock
    end
    let(:service_provider) { build(:service_provider) }

    it 'will persist the record' do
      expect(service_provider).to_not be_persisted
      subject = described_class.new(service_provider, current_user, log_mock)
      subject.validate_and_save

      expect(subject.errors).to_not be_present
      expect(service_provider.errors).to_not be_present
      expect(service_provider).to be_persisted
    end

    it 'will be saved? after validate_and_save' do
      subject = described_class.new(service_provider, current_user, log_mock)
      subject.validate_and_save
      expect(subject).to be_saved
    end
  end

  context 'with an service provider missing data' do
    let(:log_mock) do
      mock = instance_double(EventLogger)
      allow(mock).to receive(:sp_errors)
      mock
    end
    let(:service_provider) { ServiceProvider.new }

    it 'populates errors and logs on validation failure' do
      log_mock = instance_double(EventLogger)
      allow(log_mock).to receive(:sp_errors)

      service_provider = ServiceProvider.new

      subject = described_class.new(service_provider, current_user, log_mock)
      subject.validate_and_save

      expect(subject.errors).to be_present
      expect(service_provider.errors).to be_present
      expect(log_mock).to have_received(:sp_errors).with({
        errors:
         { friendly_name: ["can't be blank"],
           issuer:
           ["can't be blank",
            'is not formatted correctly. The issuer must be a unique string with no spaces.'],
           team: ['must exist'],
           user: ['must exist'] },
      })
    end

    it 'formats HTML-friendly errors' do
      service_provider = ServiceProvider.new
      service_provider.user = current_user

      subject = described_class.new(service_provider, current_user, log_mock)
      subject.validate_and_save

      expected_html = <<~ERROR_SNIPPET
        <p class='usa-alert__text'>Error(s) found in these fields:</p>
        <ul class='usa-list'>
        <li>Friendly name</li>
        <li>Issuer</li>
        <li>Team</li>
        </ul>
      ERROR_SNIPPET
      expected_html.tr!("\n", '')
      subject.compile_errors
      expect(subject.compile_errors).to eq expected_html
    end

    it 'will not be saved? after validate_and_save' do
      subject = described_class.new(service_provider, current_user, log_mock)
      subject.validate_and_save
      expect(subject).to_not be_saved
      expect(service_provider).to_not be_persisted
    end
  end
end
