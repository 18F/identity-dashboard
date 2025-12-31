require 'rails_helper'

describe ServiceProviderSaver do
  let(:current_user) { create(:user, :partner_admin) }
  let(:mock_controller) do
    mock = instance_double(ServiceProvidersController)
    allow(mock).to receive(:current_user).and_return(current_user)
    mock
  end

  it 'populates errors and logs on validation failure' do
    log_mock = instance_double(EventLogger)
    allow(mock_controller).to receive(:log).and_return(log_mock)
    allow(log_mock).to receive(:sp_errors)

    service_provider = ServiceProvider.new

    subject = described_class.new(service_provider, mock_controller)
    subject.validate_and_save

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
end
