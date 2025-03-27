require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'knows which roles are legacy admin' do
    expect(Role::LOGINGOV_ADMIN).to be_legacy_admin
    other_roles = Role::ACTIVE_ROLES_NAMES.except(:logingov_admin)
    other_roles.each do |other_role|
      expect(Role.find_by(name: other_role)).not_to be_legacy_admin
    end
  end

  it 'initializes roles' do
    logger = object_double(Rails.logger)
    allow(logger).to receive(:info).with(any_args)

    Role.find_each(&:destroy)
    Role.initialize_roles { |message| logger.info message }
    expect(logger).to have_received(:info)
      .with 'logingov_admin added to roles as Login.gov Admin'
    expect(logger).to have_received(:info)
      .with 'partner_admin added to roles as Partner Admin'
    expect(logger).to have_received(:info)
      .with 'partner_developer added to roles as Partner Developer'
    expect(logger).to have_received(:info)
      .with 'partner_readonly added to roles as Partner Readonly'
  end
end
