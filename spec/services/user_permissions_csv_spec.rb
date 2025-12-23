require 'rails_helper'

describe UserPermissionsCsv do
  describe 'when rendering' do
    let(:view_stub) { instance_double ActionView::Base }

    describe 'with legacy users that do not have a role yet' do
      let(:user_permissions) do
        [{
          issuer: 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:DEPT:APP-0',
          team_uuid: '6373a17e-954f-4ab4-b54b-487d2a5a3531',
          team_name: 'User Permissions Test',
          user_email: 'rspec@good.gov',
          role: nil,
        }]
      end

      it 'outputs a row with no role' do
        subject = described_class.new(user_permissions)
        expect(view_stub).to receive(:render) do |data|
          csv_response = CSV.parse(data[:body])
          expect(csv_response.length).to eq(2)
          expect(csv_response[0][1]).to eq('Team')
          expect(csv_response[1][1]).to eq(user_permissions[0][:team_name])
          expect(csv_response[0][4]).to eq('Role')
          expect(csv_response[1][4]).to be_blank
        end
        subject.render_in(view_stub)
      end
    end
  end
end
