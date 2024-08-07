require 'rails_helper'

describe ServiceProvidersController do
  let(:user) { create(:user, :with_teams) }
  let(:agency) { create(:agency, name: 'GSA') }
  let(:team) { create(:team, agency: agency) }
  let(:init_help_params) do
    { sign_in: {en: ''}, sign_up: {en: ''} , forgot_password: {en: ''} }
  end
  let(:sp) { create(:service_provider, :with_users_team, user: user, team: team) }
  let(:fixture_path) { File.expand_path('../fixtures', __dir__) }
  let(:logo_file_params) do
    {
      io: File.open(fixture_path + '/logo.svg'),
      filename: 'alternative_filename.svg',
      content_type: 'image/svg+xml',
    }
  end

  describe '#create' do
    before do
      sign_in(user)
    end

    context 'help_text config' do
      # group_id (team) is necessary to create a ServiceProvider.
      it('should fill selected default options: blank set') do
        help_params_0 = { sign_in: {en: 'blank'},
          sign_up: {en: 'blank'},
          forgot_password: {en: 'blank'} }
        post :create, params: { service_provider: {
          issuer: 'my.issuer.string',
          group_id: user.teams.first.id,
          friendly_name: 'ABC',
          help_text: help_params_0,
        } }
        sp_help = ServiceProvider.find_by(issuer: 'my.issuer.string')

        expect(sp_help.help_text).to eq({
          'sign_in' => {
            'en' => '',
            'es' => '',
            'fr' => '',
            'zh' => '',
          },
          'sign_up' => {
            'en' => '',
            'es' => '',
            'fr' => '',
            'zh' => '',
          },
          'forgot_password' => {
            'en' => '',
            'es' => '',
            'fr' => '',
            'zh' => '',
          },
        })
      end
      it('should fill selected default options: set 1') do
        sign_in_key = 'first_time'
        sign_up_key = 'first_time'
        forgot_password_key = 'troubleshoot_html'
        help_params_1 = { sign_in: { en: sign_in_key },
          sign_up: { en: sign_up_key },
          forgot_password: { en: forgot_password_key } }
        post :create, params: { service_provider: {
          issuer: 'my.issuer.string',
          group_id: user.teams.first.id,
          friendly_name: 'ABC',
          help_text: help_params_1,
        } }
        sp_help = ServiceProvider.find_by(issuer: 'my.issuer.string')
  
        expect(sp_help.help_text).to eq({
          'sign_in' => {
            'en' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp_help.friendly_name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp_help.friendly_name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp_help.friendly_name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp_help.friendly_name,
              locale: :zh,
            ),
          },
          'sign_up' => {
            'en' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp_help.friendly_name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp_help.friendly_name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp_help.friendly_name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp_help.friendly_name,
              locale: :zh,
            ),
          },
          'forgot_password' => {
            'en' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp_help.friendly_name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp_help.friendly_name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp_help.friendly_name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp_help.friendly_name,
              locale: :zh,
            ),
          },
        })
      end
      it('should fill selected default options: set 2') do
        sign_in_key = 'piv_cac'
        sign_up_key = 'agency_email'
        forgot_password_key = 'blank'
        help_params_2 = { sign_in: { en: sign_in_key },
          sign_up: { en: sign_up_key },
          forgot_password: { en: forgot_password_key } }
        post :create, params: { service_provider: {
          issuer: 'my.issuer.string',
          group_id: user.teams.first.id,
          friendly_name: 'ABC',
          help_text: help_params_2,
        } }
        sp_help = ServiceProvider.find_by(issuer: 'my.issuer.string')
  
        expect(sp_help.help_text).to eq({
          'sign_in' => {
            'en' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              agency: sp_help.agency.name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              agency: sp_help.agency.name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              agency: sp_help.agency.name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              agency: sp_help.agency.name,
              locale: :zh,
            ),
          },
          'sign_up' => {
            'en' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              agency: sp_help.agency.name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              agency: sp_help.agency.name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              agency: sp_help.agency.name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              agency: sp_help.agency.name,
              locale: :zh,
            ),
          },
          'forgot_password' => {
            'en' => '',
            'es' => '',
            'fr' => '',
            'zh' => '',
          },
        })
      end
    end
  end

  describe '#update' do
    before do
      sign_in(user)
    end

    context 'when a user enters data into text inputs with leading and trailing spaces' do
      it('it clears leading and trailing spaces in service provider fields') do
        put :update, params: {
          id: sp.id,
          service_provider: {
            issuer: '  urn:gov:gsa:openidconnect:profiles:sp:sso:agency:name     ',
            friendly_name: '   friendly name    ',
            description: '    This is a description.   ',
            metadata_url: ' https://metadataurl.biz   ',
            acs_url: ' https://acsurl.me  ',
            assertion_consumer_logout_service_url: '   https://logoout.biz  ',
            sp_initiated_login_url: '  https://login.me  ',
            return_to_sp_url: ' https://returntospurl.biz  ',
            failure_to_proof_url: '  https://failuretoproof.com  ',
            push_notification_url: ' https://pushnotifications.com  ',
            app_name: '   app name  ',
            help_text: init_help_params,
          },
        }
        sp.reload
        expect(sp.friendly_name).to eq('friendly name')
        expect(sp.description).to eq('This is a description.')
        expect(sp.metadata_url).to eq('https://metadataurl.biz')
        expect(sp.acs_url).to eq('https://acsurl.me')
        expect(sp.assertion_consumer_logout_service_url).to eq('https://logoout.biz')
        expect(sp.sp_initiated_login_url).to eq('https://login.me')
        expect(sp.return_to_sp_url).to eq('https://returntospurl.biz')
        expect(sp.failure_to_proof_url).to eq('https://failuretoproof.com')
        expect(sp.push_notification_url).to eq('https://pushnotifications.com')
        expect(sp.app_name).to eq('app name')
      end
    end

    context 'when uploading a logo' do
      before do
        allow(subject).to receive(:authorize_approval).and_return(true)
        allow(subject).to receive(:logo_file_param).and_return(logo_file_params)
      end

      it 'caches the logo filename on the sp' do
        put :update, 
params: { id: sp.id, service_provider: { issuer: sp.issuer, help_text: init_help_params } }
        sp.reload
        expect(sp.logo).to eq('alternative_filename.svg')
      end

      it 'caches the logo key on the sp' do
        put :update, 
params: { id: sp.id, service_provider: { issuer: sp.issuer, help_text: init_help_params } }
        sp.reload
        expect(sp.remote_logo_key).to be_present
      end

      context 'with paper trail versioning enabled', versioning: true do
        before do
          put :update, 
params: { id: sp.id, service_provider: { issuer: sp.issuer, help_text: init_help_params } }
          allow(subject).to receive(:logo_file_param).and_return(new_logo_file_params)
          put :update, 
params: { id: sp.id, service_provider: { issuer: sp.issuer, help_text: init_help_params } }
          sp.reload
        end

        let(:new_logo_file_params) do
          {
            io: File.open(fixture_path + '/logo.png'),
            filename: 'new_logo.png',
            content_type: 'image/png',
          }
        end

        it 'records the user who made the last change to the sp upon update' do
          expect(sp.versions.last.whodunnit).to eq(user.email)
        end

        it 'records the previous and current logo filename upon update' do
          logo_changes = sp.versions.last[:object_changes]['logo']
          expect(logo_changes).to eq(['alternative_filename.svg', 'new_logo.png'])
        end

        it 'records the change in remote_logo_key upon update' do
          expect(sp.versions.last[:object_changes]['remote_logo_key']).to be_present
        end
      end
    end

    context 'when deleting certs' do
      let(:sp) do
        create(:service_provider,
               :with_users_team,
               user: user,
               certs: [ build_pem(serial: 100), build_pem(serial: 200), build_pem(serial: 300) ])
      end

      it 'deletes certs with the corresponding serials' do
        put :update,
            params: {
              id: sp.id,
              service_provider: { issuer: sp.issuer, remove_certificates: ['100', '200'], 
help_text: init_help_params },
            }

        sp.reload

        expect(sp.certificates.size).to eq(1)
        expect(sp.certificates.first.serial.to_s).to eq('300')
      end
    end

    it 'adds new certs uploaded to the certs array' do
      file = Rack::Test::UploadedFile.new(
               StringIO.new(build_pem(serial: 10)),
               original_filename: 'my-cert.crt',
             )

      put :update, 
params: { id: sp.id, 
service_provider: { issuer: sp.issuer, cert: file, help_text: init_help_params } }

      sp.reload

      has_serial = sp.certificates.any? { |c| c.serial.to_s == '10' }
      expect(has_serial).to eq(true)
    end

    it 'errors when cert data is not PEM encoded' do
      file = Rack::Test::UploadedFile.new(
               StringIO.new(OpenSSL::X509::Certificate.new(build_pem).to_der),
               original_filename: 'my-cert.der',
             )

      expect do
        put :update, 
params: { id: sp.id, 
service_provider: { issuer: sp.issuer, cert: file, help_text: init_help_params } }
      end.to_not(change { sp.reload.certs&.size })
    end

    it 'does not update cert array when cert data is null/empty' do
      empty_file = Rack::Test::UploadedFile.new(
        StringIO.new(''),
        original_filename: 'my-cert.crt',
      )

      put :update, 
params: { id: sp.id, 
service_provider: { issuer: sp.issuer, cert: empty_file, help_text: init_help_params } }
      expect(sp.reload.certs&.size).to equal(0)
    end

    it 'sends a serialized service provider to the IDP' do
      allow(ServiceProviderSerializer).to receive(:new) { 'attributes' }
      allow(ServiceProviderUpdater).to receive(:post_update).and_call_original
      put :update, 
params: { id: sp.id, service_provider: { issuer: sp.issuer, help_text: init_help_params } }
      provider = ServiceProvider.find_by(issuer: sp.issuer)

      expect(ServiceProviderUpdater).to have_received(:post_update).with(
        { service_provider: 'attributes' },
      )
    end

    context 'help_text config' do
      it('should fill selected default options: set 1') do
        sign_in_key = 'first_time'
        sign_up_key = 'first_time'
        forgot_password_key = 'troubleshoot_html'
        help_params_1 = { sign_in: { en: sign_in_key },
          sign_up: { en: sign_up_key },
          forgot_password: { en: forgot_password_key } }
        put :update, 
params: { id: sp.id, service_provider: { issuer: sp.issuer, help_text: help_params_1 } }
        sp.reload

        expect(sp.help_text).to eq({
          'sign_in' => {
            'en' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp.friendly_name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp.friendly_name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp.friendly_name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.sign_in.#{sign_in_key}",
              sp_name: sp.friendly_name,
              locale: :zh,
            ),
          },
          'sign_up' => {
            'en' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp.friendly_name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp.friendly_name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp.friendly_name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.sign_up.#{sign_up_key}",
              sp_name: sp.friendly_name,
              locale: :zh,
            ),
          },
          'forgot_password' => {
            'en' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp.friendly_name,
              locale: :en,
            ),
            'es' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp.friendly_name,
              locale: :es,
            ),
            'fr' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp.friendly_name,
              locale: :fr,
            ),
            'zh' => I18n.t(
              "service_provider_form.help_text.forgot_password.#{forgot_password_key}",
              sp_name: sp.friendly_name,
              locale: :zh,
            ),
          },
        })
      end
    end
  end

  describe '#publish' do
    context 'no user' do
      it 'requires authentication' do
        post :publish

        expect(response).to redirect_to root_url
      end
    end

    context 'with user' do
      before do
        user = create(:user)
        sign_in(user)
      end

      it 'redirects to service_providers_path' do
        post :publish

        expect(response).to redirect_to service_providers_path
      end

      context 'when ServiceProviderUpdater fails' do
        before do
          stub_request(:post, IdentityConfig.store.idp_sp_url).
            to_return(status: 404)
        end

        it 'redirects to service_providers_path' do
          post :publish

          expect(response).to redirect_to service_providers_path
        end

        it 'notifies NewRelic of the error' do
          expect(::NewRelic::Agent).to receive(:notice_error)

          post :publish
        end
      end
    end

    describe '#deleted' do
      context 'when user is not admin' do
        before do
          user = create(:user)
          sign_in(user)
        end

        it 'blocks non-Login Admin users' do
          get :deleted
          expect(response.status).to eq(401)
        end
      end

      context 'when user is admin' do
        before do
          admin = create(:admin)
          sign_in(admin)
        end

        it 'allows Login Admin users' do
          get :deleted
          expect(response.status).to eq(200)
        end
      end
    end
  end
end
