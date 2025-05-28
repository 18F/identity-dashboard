require 'rails_helper'

describe PopulateRoles do
  let(:gov_account) { 'test@example.gov,Robert,Smith' }
  let(:gov_email)      { gov_account.split(',')[0] }
  let(:gov_first_name) { gov_account.split(',')[1] }
  let(:gov_last_name)  { gov_account.split(',')[2] }

  let(:nongov_account) { 'test@example.com,Bob,Walters' }
  let(:nongov_email)      { nongov_account.split(',')[0] }
  let(:nongov_first_name) { nongov_account.split(',')[1] }
  let(:nongov_last_name)  { nongov_account.split(',')[2] }

  let(:without_role_membership) { create(:user_team) }
  let(:with_role_membership) { create(:user_team, :partner_developer) }
  let(:logger) { instance_double(Logger) }

  subject { described_class.new(logger) }

  describe '#call' do
    before do
      allow(logger).to receive(:info).with(any_args)
      allow(logger).to receive(:warn).with(any_args)
    end

    context 'when the user has gov email address' do
      it 'updates role name to partner_admin' do
        user = User.create(
            email: gov_email,
            first_name: gov_first_name,
            last_name: gov_last_name,
            admin: false,
          )
        user.user_teams << without_role_membership
        subject.call
        user.reload
        expect(user.user_teams.first.role_name).to eq('partner_admin')
        expect(logger).to have_received(:info)
          .with('SUCCESS: All invalid UserTeams have been updated')
      end
    end

    context 'when the user does not have a gov email address' do
      it 'updates role name to partner_developer' do
        user = User.create(
            email: nongov_email,
            first_name: nongov_first_name,
            last_name: nongov_last_name,
            admin: false,
          )
        user.user_teams << without_role_membership
        subject.call
        user.reload
        expect(user.user_teams.first.role_name).to eq('partner_developer')
        expect(logger).to have_received(:info)
          .with('SUCCESS: All invalid UserTeams have been updated')
      end
    end

    context 'when there are no invalid or nil User Teams' do
      it 'display a message and exit script' do
        user = User.create(
            email: nongov_email,
            first_name: nongov_first_name,
            last_name: nongov_last_name,
            admin: false,
        )
        user.user_teams << with_role_membership
        subject.call
        expect(logger).to have_received(:info)
          .with('INFO: All UserTeams already have valid roles.')
      end
    end
  end
end
