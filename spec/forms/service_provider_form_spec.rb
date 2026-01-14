require 'rails_helper'

describe ServiceProviderForm do
  let(:current_user) { create(:user, :partner_admin) }

  it 'populates errors and logs on validation failure' do
    log_mock = instance_double(EventLogger)
    allow(log_mock).to receive(:sp_errors)

    service_provider = ServiceProvider.new

    subject = described_class.new(service_provider, current_user, log_mock)
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
