require 'rails_helper'

describe AnalyticsController do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { create(:user, :logingov_readonly) }
  let(:partner_admin) { create(:user, :partner_admin) }
  let(:partner_developer) { create(:user, :partner_developer) }
  let(:partner_readonly) { create(:user, :partner_readonly) }
  let(:logger_double) { instance_double(EventLogger) }
  let(:issuer) { 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test' }
  let(:issuer0) { 'urn:gov:gsa:openidconnect.profiles:sp:sso:gsa:jonathan_demo' }
  let(:admin_team) { logingov_admin.teams.first }

  before do
    allow(logger_double).to receive(:unauthorized_access_attempt)
    allow(EventLogger).to receive(:new).and_return(logger_double)
  end

  describe 'Login Admin user' do
    before do
      sign_in logingov_admin
    end

    context 'on production environments' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      context '#index' do
        it 'has GET access' do
          get :index
          expect(response).to be_ok
        end

        it 'populates dates from S3 when reports exist' do
          create(:service_provider, issuer:, team: admin_team)
          get :index
          expect(assigns(:dates)).to include('2025-04-01', '2025-08-01', '2025-12-01')
        end

        it 'falls back to monthly dates when no reports exist' do
          get :index
          dates = assigns(:dates)
          expect(dates).to include('2025-10-01')
          expect(dates.first).to eq(Date.current.beginning_of_month.strftime('%F'))
          expect(dates.last).to eq('2025-10-01')
        end

        it 'includes all teams with configs' do
          team0 = create(:team)
          team1 = create(:team)
          create(:service_provider, issuer:, team: admin_team)
          create(:service_provider, issuer: issuer0, team: team1)

          get :index
          teams = assigns(:teams)
          expect(teams).to include(admin_team, team1)
          expect(teams).to_not include(team0)
        end
      end

      describe '#fetch' do
        let(:sp_with_data) do
          create(:service_provider,
            :ready_to_activate,
            issuer:,
            team: admin_team)
        end

        it 'handles bad post parameters' do
          post :fetch, params: { team: admin_team.id, uuid: sp_with_data.uuid, date: '9999-99-99' }
          expect(response).to redirect_to(analytics_path(
            team: admin_team.id,
            uuid: sp_with_data.uuid,
            date: '9999-99-99',
          ))
          expect(assigns(:error)).to match('The link for that report was not valid.')
        end

        it 'handles good post parameters' do
          post :fetch, params: { team: admin_team.id, uuid: sp_with_data.uuid, date: '2025-12-01' }
          expect(response).to redirect_to(analytics_path(
            team: admin_team.id,
            uuid: sp_with_data.uuid,
            date: '2025-12-01',
          ))
          expect(flash[:error]).to be_blank
          expect(assigns(:error)).to be_blank
        end
      end

      describe 'format: csv' do
        let(:sp) do
          create(:service_provider,
            :ready_to_activate,
            issuer:,
            team: admin_team)
        end

        before do
          get :index, as: 'csv', params: { team: admin_team.id, uuid: sp.uuid, date: '2025-12-01' }
        end

        it 'returns a valid CSV' do
          expect(response).to be_ok
          expect(response.content_type).to eq('text/csv')
        end

        it 'uses the correct filename' do
          expect(response).to be_ok
          expect(response.headers['content-disposition']).to match(
            'filename="logingov_dol_lost_and_found_database_20251201.csv',
          )
        end

        it 'does not include extra data' do
          storage_double = AnalyticsReportStorage::Disk.new
          data_modified = JSON.parse(storage_double.fetch('4388/monthly/2025-12-01.json'))
          data_modified['data']['invalid_key'] = rand(1..1000)
          allow(storage_double).to receive(:fetch).and_call_original
          allow(storage_double).to receive(:fetch)
            .with('4388/monthly/2025-12-01.json')
            .and_return(data_modified.to_json)
          allow(AnalyticsReportStorage::Disk).to receive(:new).and_return(storage_double)
          get :index, as: 'csv', params: { uuid: sp.uuid, date: '2025-12-01' }
          expect(response.body).to_not include('invalid_key')
          csv_data = CSV.parse(response.body)
          row_headers = csv_data.map { |row| row[0] }
          expect(row_headers).to include(I18n.t('reports.count_dob_incorrect'))
          expect(row_headers.select { |header| header.match(/translation/i) }).to be_empty
        end
      end
    end

    context 'on sandbox environments' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end

      context '#index' do
        it 'does have GET access' do
          get :index
          expect(response).to be_ok
          expect(logger_double).to_not have_received(:unauthorized_access_attempt)
        end
      end
    end
  end

  describe 'Login Readonly user' do
    before do
      sign_in logingov_readonly
    end

    context 'on production environments' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      context '#index' do
        it 'has GET access' do
          get :index
          expect(response).to be_ok
        end
      end
    end

    context 'on sandbox environments' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end

      context '#index' do
        it 'has GET access' do
          get :index
          expect(response).to be_ok
        end
      end
    end
  end

  describe 'Partner user' do
    before do
      sign_in partner_admin
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
    end

    context '#index' do
      it 'has GET access' do
        get :index
        expect(response).to be_ok
      end

      it 'returns all teams with configs where partner is an Admin' do
        team0 = create(:team)
        team1 = create(:team)
        team2 = create(:team)
        create(:service_provider, :ready_to_activate, team: team0)
        create(:service_provider, :ready_to_activate, team: team1)
        create(:team_membership, :partner_admin, user: partner_admin, team: team0)
        create(:team_membership, :partner_admin, user: partner_admin, team: team2)
        create(:team_membership, :partner_developer, user: partner_admin, team: team1)

        get :index
        teams = assigns(:teams)
        expect(teams).to eq([team0])
      end
    end
  end

  describe 'Partner developer user' do
    before do
      sign_in partner_developer
    end

    context '#index' do
      it 'does not have GET access' do
        get :index
        expect(response).to be_unauthorized
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe 'Partner readonly user' do
    before do
      sign_in partner_readonly
    end

    context '#index' do
      it 'does not have GET access' do
        get :index
        expect(response).to be_unauthorized
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe 'not logged in' do
    it 'is unauthorized' do
      get :index

      expect(response).to be_unauthorized
    end
  end
end
