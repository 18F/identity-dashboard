require 'rails_helper'

RSpec.describe Seeders::Roles do
  let(:logger) { Rails.logger }

  before do
    allow(logger).to receive(:info).with(any_args)
    Role.find_each(&:destroy)
  end

  it 'initializes roles' do
    described_class.new.seed
    expect(logger).to have_received(:info)
      .with 'logingov_admin added to roles as Login.gov Admin'
    expect(logger).to have_received(:info)
      .with 'partner_admin added to roles as Partner Admin'
    expect(logger).to have_received(:info)
      .with 'partner_developer added to roles as Partner Developer'
    expect(logger).to have_received(:info)
      .with 'partner_readonly added to roles as Partner Readonly'
  end

  it 'skips roles that already exist' do
    Role.create!(name: 'partner_admin', friendly_name: 'Partner Admin')
    described_class.new.seed
    expect(logger).to_not have_received(:info)
      .with 'partner_admin added to roles as Partner Admin'
    expect(logger).to have_received(:info)
      .with 'partner_developer added to roles as Partner Developer'
  end
end
