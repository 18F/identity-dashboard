require 'rails_helper'

describe ExtractsController do
  include Devise::Test::ControllerHelpers

  let(:partner) { create(:user) }
  let(:admin) { create(:user, :logingov_admin) }
  let(:team) { create(:team) }
  let(:sp1) { create(:service_provider, :ready_to_activate, team:) }
  let(:sp2) { create(:service_provider, :ready_to_activate) }
  let(:params1) do
    { extract: {
      ticket: '1', search_by: 'teams', criteria_list: sp1.group_id
    } }
  end
  let(:logger_double) { instance_double(EventLogger) }

  before do
    allow(logger_double).to receive(:extraction_request)
    allow(logger_double).to receive(:unauthorized_access_attempt)
    allow(logger_double).to receive(:unpermitted_params_attempt)
    allow(EventLogger).to receive(:new).and_return(logger_double)
  end

  after do
    begin
      File.open("#{Dir.tmpdir}/config_extract_#{params1[:extract][:ticket]}") do |f|
        File.delete f
      end
    rescue Errno::ENOENT
    end
  end

  describe 'a non-admin user' do
    before do
      sign_in partner
    end

    context '#index' do
      it 'does not have GET access' do
        get :index
        expect(response).to be_unauthorized
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end

    context '#create' do
      it 'does not have POST access' do
        post :create, params: params1
        expect(response).to be_unauthorized
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe 'a logingov_admin user' do
    before do
      sign_in admin
    end

    context '#index' do
      it 'has GET access' do
        get :index
        expect(response).to be_ok
      end
    end

    context '#create' do
      it 'remains on the form when required params are missing' do
        post :create, params: { extract: {
          ticket: '',
          search_by: '',
          criteria_list: '',
        } }

        expect(response).to render_template 'index'
      end

      it 'flashes an error and stays on the form when there are no results' do
        post :create, params: { extract: {
          ticket: '0',
          search_by: 'issuers',
          criteria_list: 'fake:issuer',
        } }

        expect(flash[:error]).to eq('No ServiceProvider or Team rows were returned')
        expect(response).to render_template 'index'
      end

      it 'flashes a warning when only some criteria are invalid' do
        post :create, params: { extract: {
          ticket: '0',
          search_by: 'issuers',
          criteria_list: "#{sp1.issuer}, fake:issuer",
        } }

        expect(flash[:warning]).to eq('Some criteria were invalid. Please check the results.')
        expect(response).to render_template 'results'
      end

      it 'will #save_to_file with some modified attributes' do
        post :create, params: params1
        filename = "#{Dir.tmpdir}/config_extract_#{params1[:extract][:ticket]}"
        sp_data = sp1.attributes
        sp_data['team_uuid'] = sp1.team.uuid
        sp_data.delete 'remote_logo_key'
        expect(File.read filename).to eq({ teams: [team], service_providers: [sp_data] }.to_json)
        expect(response).to render_template 'results'
      end

      it 'logs extraneous params' do
        post :create, params: { extract: {
          ticket: '0',
          search_by: 'teams',
          criteria_list: sp1[:group_id],
          disallowed_param: 'I am malicious',
        } }

        expect(logger_double).to have_received(:unpermitted_params_attempt)
      end

      it '#log_request' do
        post :create, params: params1

        expect(logger_double).to have_received(:extraction_request) do |op, ex_params|
          expect(op).to eq('create')
          expect(ex_params).to include('ticket', 'search_by', 'criteria_list')
        end
      end

      it 'downloads the archive ' do
        post :create, params: params1, format: :gzip
        in_memory_file = StringIO.new response.body
        Minitar.unpack(Zlib::GzipReader.new(in_memory_file))
      end
    end
  end
end
