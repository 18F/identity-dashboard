require 'rails_helper'

feature 'Auth tokens' do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  it 'is inaccessible as a normal user' do
    login_as create(:user)
    visit auth_tokens_path
    expect(page).to have_http_status(:unauthorized)
    visit new_auth_token_path
    expect(page).to have_http_status(:unauthorized)
  end

  context 'when login.gov admin' do
    before do
      login_as logingov_admin
    end

    it 'can generate a new token' do
      visit auth_tokens_path
      click_on 'Reset auth token'
      expect(page).to have_current_path(new_auth_token_path)

      click_on 'Create new token'
      expect(page).to have_current_path(auth_tokens_path)
      expect(page).to have_content('Please copy your token')
      expect(page).to have_content('this is the only time you will have access to it')
      page_token = find('input').value
      saved_token = AuthToken.for(logingov_admin)
      expect(saved_token).to be_valid(page_token)

      visit auth_tokens_path
      expect(page).to_not have_content('Please copy your token')
      expect(page).to_not have_content('this is the only time you will have access to it')
      expect(page).to_not have_css('input')
    end
  end
end
