require 'rails_helper'

feature 'Environemnts' do
  WebMock.allow_net_connect!

  context 'any user viewing the environemnts page' do
    scenario 'should see prod, staging, int, qa and dev environments' do
      user = create(:user)

      login_as(user)
      visit env_path

      expect(page).to have_content('Production')
      expect(page).to have_content('Staging')
      expect(page).to have_content('Agency integration')
      expect(page).to have_content('Quality assurance')
      expect(page).to have_content('Development')
    end
  end
end
