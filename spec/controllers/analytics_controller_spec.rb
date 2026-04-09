require 'rails_helper'

describe AnalyticsController do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:partner_admin) { create(:user, :partner_admin) }
  let(:logger_double) { instance_double(EventLogger) }

  before do
    allow(logger_double).to receive(:unauthorized_access_attempt)
    allow(EventLogger).to receive(:new).and_return(logger_double)
  end

  describe 'Login Admin user' do
    before do
      sign_in logingov_admin
    end

    context 'on production environments' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      context '#index' do
        it 'has GET access' do
          get :index
          expect(response).to be_ok
        end
      end
    end

    context 'on sandbox environments' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end

      context '#index' do
        it 'does not have GET access' do
          get :index
          expect(response).to be_unauthorized
          expect(logger_double).to have_received(:unauthorized_access_attempt)
        end
      end
    end
  end

  describe 'Partner user' do
    before do
      sign_in partner_admin
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
    end

    context '#index' do
      it 'does not have GET access' do
        get :index
        expect(response).to be_unauthorized
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end
end
