require 'rails_helper'

describe ServiceProvidersController do
  describe '#update' do
    before do
      sign_in(user)
    end

    let(:user) { create(:user, :with_teams) }
    let(:sp) { create(:service_provider, :with_users_team, user: user) }
    let(:fixture_path) { File.expand_path('../fixtures', __dir__) }
    let(:logo_file_params) do
      {
        io: File.open(fixture_path + '/logo.svg'),
        filename: 'alternative_filename.svg',
        content_type: 'image/svg+xml',
      }
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
        allow(subject).to receive(:authorize_service_provider).and_return(true)
        allow(subject).to receive(:authorize_approval).and_return(true)
        allow(subject).to receive(:logo_file_param).and_return(logo_file_params)
      end

      it 'caches the logo filename on the sp' do
        put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer } }
        sp.reload
        expect(sp.logo).to eq('alternative_filename.svg')
      end

      it 'caches the logo key on the sp' do
        put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer } }
        sp.reload
        expect(sp.remote_logo_key).to be_present
      end

      context 'with paper trail versioning enabled', versioning: true do
        before do
          put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer } }
          allow(subject).to receive(:logo_file_param).and_return(new_logo_file_params)
          put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer } }
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
              service_provider: { issuer: sp.issuer, remove_certificates: ['100', '200'] },
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

      put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer, cert: file } }

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
        put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer, cert: file } }
      end.to_not(change { sp.reload.certs&.size })
    end

    it 'does not update cert array when cert data is null/empty' do
      empty_file = Rack::Test::UploadedFile.new(
        StringIO.new(''),
        original_filename: 'my-cert.crt',
      )

      put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer, cert: empty_file } }
      expect(sp.reload.certs&.size).to equal(0)
    end

    it 'sends a serialized service provider to the IDP' do
      allow(Faraday).to receive(:post).and_call_original
      put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer } }

      expect(Faraday).to have_received(:post).with(
        IdentityConfig.store.idp_sp_url,
        {service_provider: ServiceProviderSerializer.new(sp).as_json},
        { 'X-LOGIN-DASHBOARD-TOKEN' => IdentityConfig.store.dashboard_api_token }
      )
    end
  end
end
