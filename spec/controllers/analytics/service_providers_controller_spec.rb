require 'rails_helper'

describe Analytics::ServiceProvidersController do
  include Devise::Test::ControllerHelpers
  let(:service_provider) { create(:service_provider) }
  let(:id) { service_provider.id }

  before do
    allow(IdentityConfig.store).to receive(:analytics_dashboard_enabled).and_return(true)
  end

   describe '#show' do
     context 'when a user does not exist' do
       it 'returns unauthorized' do
         get :show, params: { id: }
         expect(response).to have_http_status(:unauthorized)
       end
     end

     context 'when a user exists' do
       before { sign_in user }
       let(:user) { create(:user) }

       context 'the user is not authorized' do
         it 'returns unauthorized' do
           get :show, params: { id: }
           expect(response).to have_http_status(:unauthorized)
         end
       end

      context 'the user is authorized' do
        let(:user) { create(:user, :logingov_admin) }

        context 'when the service provider does not exist' do
          let(:id) { 'not-real-sp' }

          it 'returns status not found' do
            # this currently fails because we are not handling when a sp is not found
            get :show, params: { id: }
            expect(response).to have_http_status(:not_found)
          end
        end

        context 'when the service provider exists' do
          it 'returns status 200' do
            get :show, params: { id: }

            expect(response).to have_http_status(:ok)
          end
        end
      end
     end
   end

   describe '#stream_daily_auths_report' do
     let(:date) { '2025-07-04' }
     let(:year) { '2025' }
     let(:user) { create(:user, :with_teams) }
      let(:id) { service_provider.id }

     let(:action) do
       get :stream_daily_auths_report,
        params: { id:, date:, year: }
     end

     context 'when a user does not exist' do
       it 'returns unauthorized' do
         action
         expect(response).to have_http_status(:unauthorized)
       end
     end

     context 'when a user exists' do
       before { sign_in user }

       context 'the user is not a member of the service provider team' do
         it 'returns unauthorized' do
           action

           # this currently fails because we are not handling when a user is not authorized
           expect(response).to have_http_status(:unauthorized)
         end
       end

      context 'the user is a member of the service provider team' do
        let(:service_provider) { create(:service_provider, with_team_from_user: user) }

        context 'when the service provider issuer does not exist' do
          let(:id) { 'not-real-issuer' }

          it 'returns status not found' do
            action

            # this currently fails bc we are not handling when the issuer is not a real issuer
            expect(response).to have_http_status(:not_found)
          end
        end

        context 'when date is not correct format' do
          let(:date) { '12-12-12' }

          it 'returns status bad request' do
            action

            expect(response).to have_http_status(:bad_request)
          end
        end

         context 'when year is not correct format' do
           let(:year) { 'twothousandtwentyfive' }

          it 'returns status bad request' do
            action

            expect(response).to have_http_status(:bad_request)
          end
         end

        context 'when the service provider exists' do
          let(:status) { 200 }
          let(:body) { {}.to_json }
          let(:analytics_base_url) { 'https://public-reporting-data.prod.login.gov' }
          let(:analytics_url) do
            "#{analytics_base_url}/prod/daily-auths-report/#{year}/#{date}.daily-auths-report.json"
          end

          before do
            stub_request(:get, analytics_url).to_return(status:, body:)
          end

          context 'when the remote server returns an error' do
            let(:status) { 404 }

            it 'returns status not found' do
              action

              expect(response).to have_http_status(:not_found)
            end
          end

          context 'when the remote server returns a successful response' do
            context 'if there are no results for that issuer' do
              context 'if the body is empty' do
                it 'returns status 200' do
                  action

                  expect(response).to have_http_status(:ok)
                  # this is failing because we are assuming there will always be a results key
                  # that may be fine, but wanted to add it as a test case to evaluate it
                  expect(response.parsed_body).to eq({ 'results' => [] })
                end
              end

              context 'if the body has no results' do
                let(:body) { { 'results' => [{}] }.to_json }

                it 'returns status 200' do
                  action

                  expect(response).to have_http_status(:ok)
                  expect(response.parsed_body).to eq({ 'results' => [] })
                end
              end

              context 'if the body has no results for that issuer' do
                let(:body) do
                  {
                    'results' => [
                      {
                        'issuer' => 'not-real-issuer',
                        'count' => 70,
                      },
                    ],
                  }.to_json
                end


                it 'returns status 200' do
                  action

                  expect(response).to have_http_status(:ok)
                  expect(response.parsed_body).to eq({ 'results' => [] })
                end
              end
            end

            context 'if the body has results for that issuer' do
              let(:body) do
                {
                  'results' => [
                    {
                      'issuer' => service_provider.issuer,
                      'count' => 70,
                    },
                  ],
                }.to_json
              end

              it 'returns the results for that issuer' do
                action

                expect(response).to have_http_status(:ok)
                results = [{ 'count' => 70, 'issuer' => service_provider.issuer }]
                expect(response.parsed_body).to eq({ 'results' => results })
              end
            end
          end
        end
      end
     end
   end
end