require 'rails_helper'

describe ServiceProvidersController do
  let(:user) { create(:user, :with_teams_dev) }
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
      File.open(File.join(fixture_path, 'logo.svg')),
      'image/svg+xml',
      true,
      original_filename: 'alternative_filename.svg',
    )
  end
  let(:logger_double) { instance_double(EventLogger) }

  before do
    allow(logger_double).to receive(:sp_created)
    allow(logger_double).to receive(:sp_updated)
    allow(logger_double).to receive(:unauthorized_access_attempt)
    allow(logger_double).to receive(:unpermitted_params_attempt)
    allow(EventLogger).to receive(:new).and_return(logger_double)
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
        expect(logger_double).to have_received(:unpermitted_params_attempt)
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

    describe 'logging' do
      it 'logs the creation before save' do
        post :create, params: { service_provider: {
          issuer: 'log.issuer.string',
          group_id: user.teams.first.id,
          friendly_name: 'Log',
        } }

        # Logging happens before save, so id is nil and we capture pending changes
        expect(logger_double).to have_received(:sp_created).with(
          { changes: hash_including(pending_changes_for_create) },
        )
      end
    end

    # rubocop:disable Layout/LineLength
    describe 'UUID assignment' do
      it 'assigns a UUID to the service provider' do
        post :create, params: { service_provider: {
          issuer: 'uuid.test.issuer',
          group_id: user.teams.first.id,
          friendly_name: 'UUID Test',
        } }

        service_provider = ServiceProvider.find_by(issuer: 'uuid.test.issuer')
        expect(service_provider.uuid).to_not be_nil
        expect(service_provider.uuid).to match(/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}/)
      end
    end
    # rubocop:enable Layout/LineLength
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
            app_name: '   configuration name  ',
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
        expect(sp.app_name).to eq('configuration name')
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
            File.open(File.join(fixture_path, 'logo.png')),
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

        expect(logger_double).to receive(:sp_errors).with({
          errors: { logo_file: [
            'The logo file you uploaded (logo_without_size.svg) is missing a viewBox. ' \
            'Please add a viewBox attribute to your SVG and re-upload',
          ] },
        })

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

      describe 'with previously saved file that is too big' do
        let(:logo_file_params) do
          Rack::Test::UploadedFile.new(
            File.open(File.join(fixture_path, '..', 'big-logo.png')),
            'image/png',
            true,
            original_filename: 'big-logo.png',
          )
        end

        before do
          sp.logo_file.attach(logo_file_params)
          sp.save!(validate: false)
        end

        it 'fails when uploading a big file' do
          expect(logger_double).to receive(:sp_errors).with({
            errors: { logo_file: ['must be less than 50kB'] },
          })
          put :update, params: {
            id: sp.id,
            service_provider: sp_logo_params,
          }
          expect(flash['error']).to_not be_blank
          expect(flash['error']).to include(I18n.t('service_provider_form.title.logo_file'))
        end

        it 'does not fail if not updating the file' do
          sp_logo_params.delete(:logo_file)
          put :update, params: {
            id: sp.id,
            service_provider: sp_logo_params,
          }
          expect(flash['error']).to be_blank
        end
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
      expect(logger_double).to receive(:sp_errors).with({
        errors: { certs: ['Certificate is not PEM-encoded'] },
      })
      expect do
        put :update, params: {
          id: sp.id,
          service_provider: { issuer: sp.issuer, cert: file, help_text: init_help_params },
        }
      end.to_not(change { sp.reload.certs&.size })
    end

    it 'logs a cert error no matter how invalid the cert is' do
      image_file = fixture_file_upload('logo.png')

      expect(logger_double).to receive(:sp_errors).with({
        errors: { certs:
          ['is invalid - PEM_read_bio_X509: no start line (Expecting: CERTIFICATE)',
           'Certificate is not PEM-encoded'] },
      })

      put :update, params: {
        id: sp.id,
        service_provider: { issuer: sp.issuer, cert: image_file },
      }
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
          create(:team_membership, :partner_developer, user: user, team: sp.team)
          sign_in user
        end

        it 'rejects help text params if any are custom' do
          original_help_text = sp.help_text
          custom_params = {
            sign_in: { en: 'random' },
            sign_up: { en: 'custom' },
            forgot_password: { en: 'blank' },
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
            forgot_password: { en: 'blank' },
          }

          put :update, params: {
            id: sp.id,
            service_provider: { issuer: sp.issuer, help_text: custom_params },
          }
          sp.reload
          expect(sp.help_text['sign_in']['en']).to_not eq(original_help_text['sign_in']['en'])
          expect(sp.help_text['sign_in']['en']).to eq(
            t('service_provider_form.help_text.sign_in.first_time',
              sp_name: sp.friendly_name),
          )
          expect(sp.help_text['sign_up']['en']).to_not eq(original_help_text['sign_up']['en'])
          expect(sp.help_text['forgot_password']['en'])
            .to_not eq(original_help_text['forgot_password']['en'])
        end
      end
    end

    describe 'Production gate is enabled' do
      let(:prod_app) { create(:service_provider, :with_ial_1, :with_prod_config, team:) }

      before do
        allow(IdentityConfig.store).to receive_messages(prod_like_env: true)
      end

      context 'with Partner user' do
        before do
          create(:team_membership, :partner_admin, user: user, team: prod_app.team)
          sign_in(user)
          prod_app.ial = '1'
        end

        it 'does not allow updates to IAL' do
          put :update, params: {
            id: prod_app.id,
            service_provider: { issuer: prod_app.issuer, ial: '2' },
          }
          prod_app.reload
          expect(prod_app.ial).to eq(1)
          expect(logger_double).to have_received(:unpermitted_params_attempt)
        end

        describe 'logging' do
          let(:description) { "logging test #{rand(1...1000)}" }
          let(:changes) do
            {
              'description' => {
                'new' => description,
                'old' => prod_app.description,
              },
              'id' => prod_app.id,
            }
          end

          it 'logs changes' do
            put :update, params: {
              id: prod_app.id,
              service_provider: { description: },
            }

            expect(logger_double).to have_received(:sp_updated).with({ changes: })
          end
        end
      end

      context 'with Login.gov Admin' do
        before do
          sign_in(logingov_admin)
        end

        it 'allows updates to IAL' do
          put :update, params: {
            id: prod_app.id,
            service_provider: { issuer: prod_app.issuer, ial: 2 },
          }
          prod_app.reload
          expect(prod_app.ial).to eq(2)
        end
      end
    end
  end

  describe '#destroy' do
    before do
      allow(logger_double).to receive(:sp_destroyed)

      create(:team_membership, :partner_admin, user: user, team: sp.team)
      sign_in user
    end

    it 'logs delete events' do
      delete :destroy, params: { id: sp.id }

      # timestamp granularity is different between DB and Ruby
      changes = sp.attributes.except('updated_at', 'created_at')

      expect(logger_double).to have_received(:sp_destroyed).with(
        { changes: hash_including(changes) },
      )
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
          stub_request(:post, IdentityConfig.store.idp_sp_url)
            .to_return(status: 404)
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
          expect(logger_double).to have_received(:unauthorized_access_attempt)
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

  describe '#show' do
    let(:sp_with_uuid) { create(:service_provider, team: team, uuid: SecureRandom.uuid) }

    before do
      sign_in(logingov_admin)
    end

    context 'when accessed by id' do
      it 'finds the service provider' do
        get :show, params: { id: sp_with_uuid.id }
        expect(response).to have_http_status(:ok)
        expect(assigns(:service_provider)).to eq(sp_with_uuid)
      end
    end

    context 'when accessed by uuid' do
      it 'finds the service provider' do
        get :show, params: { id: sp_with_uuid.uuid }
        expect(response).to have_http_status(:ok)
        expect(assigns(:service_provider)).to eq(sp_with_uuid)
      end
    end
  end

  describe '#edit' do
    let(:sp_with_uuid) { create(:service_provider, team: team, uuid: SecureRandom.uuid) }

    before do
      sign_in(logingov_admin)
    end

    context 'when accessed by uuid' do
      it 'finds the service provider' do
        get :edit, params: { id: sp_with_uuid.uuid }
        expect(assigns(:service_provider)).to eq(sp_with_uuid)
      end
    end
  end

  def changes(service_provider:)
    {
      'id' => service_provider.id,
      'friendly_name' => { 'new' => service_provider.friendly_name, 'old' => nil },
      'group_id' => { 'new' => service_provider.group_id, 'old' => nil },
      'issuer' => { 'new' => service_provider.issuer, 'old' => nil },
      'status' => { 'new' => service_provider.status, 'old' => 'pending' },
      'user_id' => { 'new' => user.id, 'old' => nil },
    }
  end

  # Pending changes captured before save (id is nil, no status change)
  def pending_changes_for_create
    {
      'id' => nil,
      'friendly_name' => { 'new' => 'Log', 'old' => nil },
      'group_id' => { 'new' => user.teams.first.id, 'old' => nil },
      'issuer' => { 'new' => 'log.issuer.string', 'old' => nil },
      'user_id' => { 'new' => user.id, 'old' => nil },
    }
  end
end
