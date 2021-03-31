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
    end

    it 'adds new certs uploaded to the certs array' do
    end
  end
end
