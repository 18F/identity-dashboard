require 'rails_helper'
require 'pry'

RSpec.describe ServiceConfigWizardController do
  let(:user) { create(:user, uuid: SecureRandom.uuid, admin: false) }
  let(:admin) { create(:user, uuid: SecureRandom.uuid, admin: true) }

  def flag_in
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(true)
  end

  def flag_out
    expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(false)
  end

  context 'as an admin' do
    before do
      sign_in admin
    end

    it 'can start the first step' do
      flag_in
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
    end

    it 'will be redirected if the flag is not set' do
      flag_out
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_providers_url)
    end
  end

  context 'as a non-admin user' do
    before do
      sign_in user
    end

    it 'can start the first step' do
      flag_in
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_config_wizard_url(Wicked::FIRST_STEP))
    end

    it 'will be redirected if the flag is not set' do
      flag_out
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(service_providers_url)
    end
  end

  context 'when not logged in' do
    it 'requires authentication without checking flag status' do
      expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).never
      get :new
      expect(response).to be_redirect
      expect(response.redirect_url).to eq(root_url)
    end
  end

  describe '#update' do
    let(:team) { create(:team)}
    let(:some_setup_params) {{
      group_id: team.id,
      prod_config: false,
      friendly_name: "A Friendly Test App",
    }}
    before do
      flag_in
      sign_in user
    end

    context 'without an existing draft' do
      it 'saves valid data to a draft' do
        patch :update, params: { id: :settings, service_provider: some_setup_params}
        assigns[:service_provider].attributes.each do |(actual_key, actual_value)|
          if some_setup_params.has_key?(actual_key.to_sym)
            expect(actual_value).to eq(some_setup_params[actual_key.to_sym].to_s)
          end
        end
      end

      it 'sets an error for invalid data while still persisting the draft' do
        # A friendly_name is required for step :settings
        some_setup_params[:friendly_name] = ''
        patch :update, params: { id: :settings, service_provider: some_setup_params}

        # Sets error
        expect(assigns[:service_provider].errors.count).to be(1)
        error = assigns[:service_provider].errors.first
        expect(error.full_message).to eq("Friendly name can't be blank")

        # Still persists the supplied info
        assigns[:service_provider].attributes.each do |(actual_key, actual_value)|
          if some_setup_params.has_key?(actual_key.to_sym)
            expect(actual_value).to eq(some_setup_params[actual_key.to_sym].to_s)
          end
        end
      end
    end
  end
end
