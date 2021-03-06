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

    context 'when eventbridge is enabled' do
      before do
        allow(Identity::Hostdata).to receive(:env).and_return('int')
        allow(IdentityConfig.store).to receive(:risc_notifications_eventbridge_enabled).
          and_return(true)

        Aws.config[:eventbridge] = {
          stub_responses: {
            list_connections: { connections: [] },
            create_connection: { connection_arn: 'example-arn' },
            update_connection: { connection_arn: 'example-arn' },
            list_api_destinations: { api_destinations: [] },
            list_rules: { rules: [] },
            list_targets_by_rule: { targets: [] },
          },
        }
      end

      it 'updates' do
        put :update,
            params: {
              id: sp.id,
              service_provider: {
                issuer: sp.issuer,
                push_notification_url: 'https://example.com/push',
              },
            }
      end
    end
  end
end
