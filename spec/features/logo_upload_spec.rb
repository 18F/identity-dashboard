require 'rails_helper'

feature 'Logo upload' do
  let(:user) { create(:user, :with_teams) }
  before do
    ENV['logo_upload_enabled'] = 'true'
  end

  context 'on create' do
    before do
      login_as(user)
      visit new_service_provider_path

      fill_in 'Friendly name', with: 'test service_provider'
      fill_in 'Issuer', with: 'urn:gov:gsa:openidconnect.profiles:sp:sso:GSA:app-prod'
      select user.teams[0].name, from: 'service_provider_group_id'
    end

    it 'saves the logo' do
      attach_file('Choose a file', 'spec/fixtures/logo.svg')
      click_on 'Create'

      sp = user.service_providers.last

      expect(sp.logo_file).to_not eq(nil)
    end

    it 'renders an error if the logo has an invalid MIME type' do
      attach_file('Choose a file', 'spec/fixtures/invalid.txt')
      click_on 'Create'

      expect(page).to have_content(
        'The file you uploaded (invalid.txt) is not a PNG or SVG',
      )
      expect(user.reload.service_providers.count).to eq(0)
    end
  end

  context 'on update' do
    let(:service_provider) { create(:service_provider, user: user) }

    before do
      login_as(user)
      visit edit_service_provider_path(service_provider)
    end

    it 'saves the logo' do
      attach_file('Choose a file', 'spec/fixtures/logo.svg')
      click_on 'Update'

      expect(service_provider.reload.logo_file).to_not eq(nil)
    end

    it 'renders an error if the logo has an invalid MIME type' do
      attach_file('Choose a file', 'spec/fixtures/invalid.txt')
      click_on 'Update'

      expect(page).to have_content(
        'The file you uploaded (invalid.txt) is not a PNG or SVG',
      )
      expect(service_provider.reload.logo_file.attachment).to eq(nil)
    end
  end
end
