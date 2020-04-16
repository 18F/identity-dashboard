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
        allow(Figaro.env).to receive(:AWS_REGION).and_return('us-west-2')
        allow(subject).to receive(:using_s3?).and_return(true)
        allow(subject).to receive(:logo_file_param).and_return(
          {
            io: File.open(fixture_path + '/logo.svg'),
            filename: 'logo.svg',
            content_type: 'image/svg'
          }
        )
        allow_any_instance_of(Aws::S3::Client).to receive(:copy_object)

        stub_request(:put, "http://169.254.169.254/latest/api/token").
          with(
            headers: {
              'Accept'=>'*/*',
              'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent'=>'aws-sdk-ruby3/3.90.1',
              'X-Aws-Ec2-Metadata-Token-Ttl-Seconds'=>'21600'
            }).
          to_return(status: 200, body: "", headers: {})
        stub_request(:get, "http://169.254.169.254/latest/meta-data/iam/security-credentials/").
          with(
            headers: {
              'Accept'=>'*/*',
              'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent'=>'aws-sdk-ruby3/3.90.1'
            }).
          to_return(status: 200, body: "", headers: {})
      end

      it 'calls copy_object on the S3 client to set content-type' do
        expect(subject.send(:s3)).to receive(:copy_object)
        put :update, params: { id: sp.id, service_provider: { issuer: sp.issuer } }
      end
    end
  end
end
