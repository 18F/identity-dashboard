require 'rails_helper'

describe ServiceProvidersController do
  describe '#update' do
    before do
      user = create(:user)
      sign_in(user)
    end

    let(:sp) { create(:service_provider) }
    let(:fixture_path) { File.expand_path('../fixtures', __dir__) }

    context 'when uploading a logo to S3' do
      before do
        allow(subject).to receive(:authorize_service_provider).and_return(true)
        allow(subject).to receive(:authorize_approval).and_return(true)
        allow(subject).to receive(:using_s3?).and_return(true)
        allow(subject).to receive(:logo_file_param).and_return(
          {
            io: File.open(fixture_path + '/logo.svg'),
            filename: 'logo.svg',
            content_type: 'image/svg'
          }
        )
        allow(subject).to receive(:s3).and_return(Aws::S3::Client.new(stub_responses: true))
      end

      it 'calls copy_object on the S3 client to set content-type' do
        expect(subject.send(:s3)).to receive(:copy_object)
        put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer } }
      end
    end
  end
end
