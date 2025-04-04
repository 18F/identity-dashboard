require 'rails_helper'

describe ServiceProvidersController do
  let(:user) { create(:user, :with_teams) }
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:agency) { create(:agency, name: 'GSA') }
  let(:team) { create(:team, agency:) }
  let(:init_help_params) do
    { sign_in: { en: '' }, sign_up: { en: '' }, forgot_password: { en: '' } }
  end
  let(:sp) { create(:service_provider, team: team, ial: 1) }
  let(:fixture_path) { File.expand_path('../fixtures/files', __dir__) }
  let(:logo_file_params) do
    Rack::Test::UploadedFile.new(
      File.open(fixture_path + '/logo.svg'),
      'image/svg+xml',
      true,
      original_filename: 'alternative_filename.svg',
    )
  end

  describe '#create' do
    before do
      sign_in(user)
    end

    context 'help_text config' do
      # group_id (team) is necessary to create a ServiceProvider.
      it('fills selected default options: blank set') do
        help_params_0 = { sign_in: { en: 'blank' },
          sign_up: { en: 'blank' },
          forgot_password: { en: 'blank' } }
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

      it('fills selected default options: set 1') do
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

      it('fills selected default options: set 2') do
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

    context 'email_nameid_format_allowed permissions as user' do
      it('does not allow non-Login Admin users to set Email NameID Format') do
        post :create, params: { service_provider: {
          issuer: 'my.issuer.string',
          group_id: user.teams.first.id,
          friendly_name: 'ABC',
          email_nameid_format_allowed: true,
        } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'email_nameid_format_allowed permissions as admin' do
      before do
        sign_in(logingov_admin)
      end

      it('allows Login Admin users to set Email NameID Format') do
        post :create, params: { service_provider: {
          issuer: 'my.issuer.string',
          group_id: user.teams.first.id,
          friendly_name: 'ABC',
          email_nameid_format_allowed: true,
        } }
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe '#update' do
    before do
      sign_in(logingov_admin)
    end

    context 'when a user enters data into text inputs with leading and trailing spaces' do
      it('clears leading and trailing spaces in service provider fields') do
        put :update, params: {
          id: sp.id,
          service_provider: {
            issuer: '  urn:gov:gsa:openidconnect:profiles:sp:sso:agency:name     ',
            identity_protocol: 'saml',
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
      let(:sp_logo_params) do
        {
          issuer: sp.issuer,
          help_text: init_help_params,
          logo_file: logo_file_params,
          approved: true,
        }
      end

      it 'caches the logo filename on the sp' do
        put :update, params: {
          id: sp.id,
          service_provider: sp_logo_params,
        }
        sp.reload
        expect(sp.logo).to eq('alternative_filename.svg')
      end

      it 'caches the logo key on the sp' do
        put :update, params: {
          id: sp.id,
          service_provider: sp_logo_params,
        }
        sp.reload
        expect(sp.remote_logo_key).to be_present
      end

      context 'with paper trail versioning enabled', :versioning do
        before do
          put :update, params: {
            id: sp.id,
            service_provider: sp_logo_params,
          }
          put :update, params: {
            id: sp.id,
            service_provider: sp_logo_params.merge(logo_file: new_logo_file_params),
          }
          sp.reload
        end

        let(:new_logo_file_params) do
          Rack::Test::UploadedFile.new(
            File.open(fixture_path + '/logo.png'),
            'image/png',
            true,
            original_filename: 'new_logo.png',
          )
        end

        it 'records the user who made the last change to the sp upon update' do
          expect(sp.versions.last.whodunnit).to eq(logingov_admin.email)
        end

        it 'records the previous and current logo filename upon update' do
          logo_changes = sp.versions.last[:object_changes]['logo']
          expect(logo_changes).to eq(['alternative_filename.svg', 'new_logo.png'])
        end

        it 'records the change in remote_logo_key upon update' do
          expect(sp.versions.last[:object_changes]['remote_logo_key']).to be_present
        end
      end

      it 'does not allow a bad logo to overwrite a good logo' do
        expect(sp.logo_file).to be_blank
        put :update, params: {
          id: sp.id,
          service_provider: sp_logo_params,
        }

        sp.reload
        expected_checksum = OpenSSL::Digest.base64digest('MD5', logo_file_params.read)
        initial_key = sp.remote_logo_key
        expect(sp.logo_file.checksum).to eq(expected_checksum)
        bad_logo = fixture_file_upload('../logo_without_size.svg')
        bad_logo_checksum = OpenSSL::Digest.base64digest('MD5', bad_logo.read)

        put :update, params: {
          id: sp.id,
          service_provider: sp_logo_params.merge(logo_file: bad_logo),
        }

        sp.reload
        expect(sp.remote_logo_key).to eq(initial_key)
        expect(sp.logo).to eq('alternative_filename.svg')
        expect(sp.logo_file.checksum).to_not eq(bad_logo_checksum)
        expect(sp.logo_file.checksum).to eq(expected_checksum)
      end
    end

    context 'when deleting certs' do
      let(:sp) do
        create(:service_provider,
               team: team,
               certs: [build_pem(serial: 100), build_pem(serial: 200), build_pem(serial: 300)])
      end

      it 'deletes certs with the corresponding serials' do
        put :update,
            params: {
              id: sp.id,
              service_provider: {
                issuer: sp.issuer,
                remove_certificates: ['100', '200'],
                help_text: init_help_params,
              },
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

      put :update, params: {
        id: sp.id,
        service_provider: { issuer: sp.issuer, cert: file, help_text: init_help_params },
      }

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
        put :update, params: {
          id: sp.id,
          service_provider: { issuer: sp.issuer, cert: file, help_text: init_help_params },
        }
      end.to_not(change { sp.reload.certs&.size })
    end

    it 'does not update cert array when cert data is null/empty' do
      empty_file = Rack::Test::UploadedFile.new(
        StringIO.new(''),
        original_filename: 'my-cert.crt',
      )

      put :update, params: {
        id: sp.id,
        service_provider: { issuer: sp.issuer, cert: empty_file, help_text: init_help_params },
      }
      expect(sp.reload.certs&.size).to equal(0)
    end

    it 'sends a serialized service provider to the IDP' do
      allow(ServiceProviderSerializer).to receive(:new).and_return('attributes')
      allow(ServiceProviderUpdater).to receive(:post_update).and_call_original
      put :update, params: {
        id: sp.id,
        service_provider: { issuer: sp.issuer, help_text: init_help_params },
      }
      provider = ServiceProvider.find_by(issuer: sp.issuer)

      expect(ServiceProviderUpdater).to have_received(:post_update).with(
        { service_provider: 'attributes' },
      )
    end

    context 'help_text config' do
      it('fills selected default options: set 1') do
        sign_in_key = 'first_time'
        sign_up_key = 'first_time'
        forgot_password_key = 'troubleshoot_html'
        help_params_1 = { sign_in: { en: sign_in_key },
          sign_up: { en: sign_up_key },
          forgot_password: { en: forgot_password_key } }
        put :update, params: {
          id: sp.id,
          service_provider: { issuer: sp.issuer, help_text: help_params_1 },
        }
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

      context 'when not a Login.gov admin' do
        before do
          create(:user_team, :partner_developer, user: user, team: sp.team)
          sign_in user
        end

        it 'rejects help text params if any are custom' do
          original_help_text = sp.help_text
          custom_params = {
            sign_in: { en: 'random' },
            sign_up: { en: 'custom' },
            forgot_password: { en:'blank' },
          }
          put :update, params: {
            id: sp.id,
            service_provider: { issuer: sp.issuer, help_text: custom_params },
          }
          sp.reload
          expect(sp.help_text['sign_in']['en']).to eq(original_help_text['sign_in']['en'])
          expect(sp.help_text['sign_up']['en']).to eq(original_help_text['sign_up']['en'])
          expect(sp.help_text['forgot_password']['en'])
            .to eq(original_help_text['forgot_password']['en'])
        end

        it 'allows help text params if all are presets' do
          original_help_text = sp.help_text
          custom_params = {
            sign_in: { en: 'first_time' },
            sign_up: { en: 'first_time' },
            forgot_password: { en:'blank' },
          }

          put :update, params: {
            id: sp.id,
            service_provider: { issuer: sp.issuer, help_text: custom_params },
          }
          sp.reload
          expect(sp.help_text['sign_in']['en']).to_not eq(original_help_text['sign_in']['en'])
          expect(sp.help_text['sign_in']['en']).to eq(t(
            'service_provider_form.help_text.sign_in.first_time',
            sp_name: sp.friendly_name,
          ))
          expect(sp.help_text['sign_up']['en']).to_not eq(original_help_text['sign_up']['en'])
          expect(sp.help_text['forgot_password']['en'])
            .to_not eq(original_help_text['forgot_password']['en'])
        end
      end
    end

    describe 'Production gate is enabled' do
      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: true)
      end

      context 'with Partner user' do
        before do
          sign_in(user)
          sp.ial = '1'
        end

        it 'does not allow updates to IAL' do
          put :update, params: {
            id: sp.id,
            service_provider: { issuer: sp.issuer, ial: '2' },
          }
          sp.reload
          expect(sp.ial).to eq(1)
        end
      end

      context 'with Login.gov Admin' do
        before do
          sign_in(logingov_admin)
        end

        it 'allows updates to IAL' do
          put :update, params: {
            id: sp.id,
            service_provider: { issuer: sp.issuer, ial: 2 },
          }
          sp.reload
          expect(sp.ial).to eq(2)
        end
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
          expect(NewRelic::Agent).to receive(:notice_error)

          post :publish
        end
      end
    end

    describe '#deleted' do
      context 'when not login.gov admin' do
        before do
          user = create(:user)
          sign_in(user)
        end

        it 'blocks non-Login Admin users' do
          get :deleted
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when user is login.gov admin' do
        before do
          sign_in(create(:logingov_admin))
        end

        it 'allows Login Admin users' do
          get :deleted
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
