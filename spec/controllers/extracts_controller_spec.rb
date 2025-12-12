require 'rails_helper'

describe ExtractsController do
  include Devise::Test::ControllerHelpers

  let(:partner) { create(:user) }
  let(:logingov_admin) { create(:user, :logingov_admin) }
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
      sign_in logingov_admin
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

      context 'has a service provider with a logo file' do
        before do
          sp1.logo_file = fixture_file_upload('logo.svg')
          sp1.save!
          post :create, params: params1, format: :gzip
          in_memory_file = StringIO.new response.body, binmode: true
          Minitar.unpack(Zlib::GzipReader.new(in_memory_file), 'tmp')
        end

        after do
          system "rm tmp//#{sp1.id}_logo.svg"
          system 'rm tmp/extract.json'
        end

        it 'contains a logo file' do
          expect(File.read("tmp/#{sp1.id}_logo.svg")).to eq(sp1.logo_file.download)
        end

        it 'contains the json data' do
          expect(JSON.parse(File.read('tmp/extract.json'))).to_not be_blank
        end
      end

      it 'works with fully-translated help text strings' do
        sp1.help_text = { 'sign_up' => { 'en' => 'first_time' } }
        sp1.help_text = HelpText.lookup(service_provider: sp1).to_localized_h
        sp1.save!

        post :create, params: params1, format: :gzip

        in_memory_file = StringIO.new response.body, binmode: true
        Minitar.unpack(Zlib::GzipReader.new(in_memory_file), 'tmp')
        extracted_data = JSON.parse(File.read('tmp/extract.json'))

        expect(extracted_data['service_providers'].count).to be 1
        extracted_help_text = extracted_data['service_providers'].first['help_text']
        expect(extracted_help_text).to eq(sp1.help_text)
        expect(extracted_help_text['sign_up']['zh']).to include('第一')

        system 'rm tmp/extract.json'
      end
    end
  end
end
