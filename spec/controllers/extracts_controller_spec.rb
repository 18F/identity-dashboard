require 'rails_helper'

describe ExtractsController do
  include Devise::Test::ControllerHelpers

  let(:partner) { create(:user) }
  let(:admin) { create(:user, :logingov_admin) }
  let(:sp1) { create(:service_provider, :ready_to_activate ) }
  let(:sp2) { create(:service_provider, :ready_to_activate ) }
  let(:params1) do
    { extract: {
      ticket: '1', search_by: 'teams', criteria_list: sp1.group_id
    } }
  end
  let(:logger_double) { instance_double(EventLogger) }

  before do
    allow(logger_double).to receive(:extraction_request)
    allow(logger_double).to receive(:unauthorized_access_attempt)
    allow(EventLogger).to receive(:new).and_return(logger_double)
  end

  after do
    begin
      File.open("/tmp/config_extract_#{params1[:extract][:ticket]}") do |f|
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
      end
    end

    context '#create' do
      it 'does not have POST access' do
        post :create, params: params1
        expect(response).to be_unauthorized
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
      it 'includes errors when required params are missing' do
        post :create, params: { extract: {
          search_by: '',
        } }

        expect(assigns[:extract].errors).to include(
          :ticket,
          :search_by,
          :criteria_file,
          :criteria_list,
        )
      end

      it 'distinguishes between valid and invalid teams' do
        post :create, params: { extract: {
          ticket: '0',
          search_by: 'teams',
          criteria_list: "#{sp1.group_id},999",
        } }

        expect(assigns[:successes]).to include(sp1)
        expect(assigns[:failures]).to include('999')
      end

      it 'distinguishes between valid and invalid issuers' do
        post :create, params: { extract: {
          ticket: '0',
          search_by: 'issuers',
          criteria_list: "#{sp1.issuer} fake:issuer",
        } }

        expect(assigns[:successes]).to include(sp1)
        expect(assigns[:failures]).to include('fake:issuer')
      end

      it 'concatenates a file and input data' do
        File.open('/tmp/config_extract_test', 'w') do |f|
          f.print sp2[:group_id]
        end
        test_params = params1
        test_params[:extract][:criteria_file] = Rack::Test::UploadedFile.new(
          '/tmp/config_extract_test',
          'text/plain',
        )
        post :create, params: test_params

        expect(assigns[:successes]).to include(sp1, sp2)
        expect(assigns[:failures]).to eq([])
      end

      it 'will #save_to_file' do
        post :create, params: params1

        expect(File.read "/tmp/config_extract_#{assigns[:ticket]}").to eq([sp1].to_json)
      end

      it 'logs extract requests' do
        post :create, params: params1

        expect(logger_double).to have_received(:extraction_request) do |op, ex_params|
          expect(op).to eq('create')
          expect(ex_params).to include('ticket', 'search_by', 'criteria_list')
        end
      end
    end
  end
end
