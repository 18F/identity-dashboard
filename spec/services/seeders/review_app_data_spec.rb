require 'rails_helper'

RSpec.describe Seeders::ReviewAppData do
  let(:logger) { Rails.logger }

  before do
    allow(logger).to receive(:info).with(any_args)
  end

  context 'when POSTGRES_HOST is not review-app' do
    it 'does nothing' do
      expect { described_class.new.seed }.to_not change { User.count }
    end
  end

  context 'when POSTGRES_HOST is review-app' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('POSTGRES_HOST').and_return('db.review-app.example.com')   
    end

    it 'seeds users' do
      expect { described_class.new.seed }.to change { User.count }.by 5

      expect(User.find_by(email: 'logingov-admin@gsa.gov')).to be_present
      expect(User.find_by(email: 'logingov-readonly@gsa.gov')).to be_present
      expect(User.find_by(email: 'partner-admin@gsa.gov')).to be_present
      expect(User.find_by(email: 'partner-developer@gsa.gov')).to be_present
      expect(User.find_by(email: 'partner-readonly@gsa.gov')).to be_present

      expect(logger).to have_received(:info).with('Created user: logingov-admin@gsa.gov')
      expect(logger).to have_received(:info).with('Created user: logingov-readonly@gsa.gov')
      expect(logger).to have_received(:info).with('Created user: partner-admin@gsa.gov')
      expect(logger).to have_received(:info).with('Created user: partner-developer@gsa.gov')
      expect(logger).to have_received(:info).with('Created user: partner-readonly@gsa.gov')
    end

    it 'seeds teams' do
      expect { described_class.new.seed }.to change { Team.count }.by 2

      expect(Team.find_by(name: 'Production Team')).to be_present
      expect(Team.find_by(name: 'Sandbox Team')).to be_present

      expect(logger).to have_received(:info).with('Created team: Production Team')
      expect(logger).to have_received(:info).with('Created team: Sandbox Team')
    end

    it 'seeds team_memberships' do
      described_class.new.seed

      expect(logger).to have_received(:info)
        .with('Assigned logingov-admin@gsa.gov to Login.gov Internal Team as logingov_admin')
      expect(logger).to have_received(:info)
        .with('Assigned logingov-admin@gsa.gov to Production Team as partner_admin')
      expect(logger).to have_received(:info)
        .with('Assigned logingov-admin@gsa.gov to Sandbox Team as partner_admin')
      expect(logger).to have_received(:info)
        .with('Assigned logingov-readonly@gsa.gov to Login.gov Internal Team as logingov_readonly')
      expect(logger).to have_received(:info)
        .with('Assigned logingov-readonly@gsa.gov to Production Team as partner_readonly')
      expect(logger).to have_received(:info)
        .with('Assigned logingov-readonly@gsa.gov to Sandbox Team as partner_readonly')
      expect(logger).to have_received(:info)
        .with('Assigned partner-admin@gsa.gov to Production Team as partner_admin')
      expect(logger).to have_received(:info)
        .with('Assigned partner-admin@gsa.gov to Sandbox Team as partner_admin')
      expect(logger).to have_received(:info)
        .with('Assigned partner-developer@gsa.gov to Production Team as partner_developer')
      expect(logger).to have_received(:info)
        .with('Assigned partner-developer@gsa.gov to Sandbox Team as partner_developer')
      expect(logger).to have_received(:info)
        .with('Assigned partner-readonly@gsa.gov to Production Team as partner_readonly')
      expect(logger).to have_received(:info)
        .with('Assigned partner-readonly@gsa.gov to Sandbox Team as partner_readonly')
    end

    it 'seeds configurations' do
      expect { described_class.new.seed }.to change { ServiceProvider.count }.by 4
      expect(logger).to have_received(:info).with('Created service provider: Prod OIDC')
      expect(logger).to have_received(:info).with('Created service provider: Prod SAML')
      expect(logger).to have_received(:info).with('Created service provider: Sandbox OIDC')
      expect(logger).to have_received(:info).with('Created service provider: Sandbox SAML')
    end

    it 'is idempotent' do
      2.times { described_class.new.seed }
      expect(User.where(email: 'partner-admin@gsa.gov').count).to eq(1)
    end
  end
end
