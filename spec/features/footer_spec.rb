require 'rails_helper'

feature 'Footer' do
  let(:user) { create(:user) }
  let(:footer) { page.find('footer') }

  before do
    login_as(user)
    visit root_path
  end

  context 'main section' do
    let(:section) { footer.find('.footer-navigation') }

    scenario 'should include the Login.gov logo' do
      expect(section).to have_css('[alt="Login.gov logo"]')
    end

    scenario 'should include system status link' do
      status_link = section.find('[href="https://status.login.gov"]')

      expect(status_link.tag_name).to eq('a')
      expect(status_link).to have_content('Login.gov system status')
    end
  end

  context 'links section' do
    let(:section) { footer.find('.footer__signed-in') }

    scenario 'should include GSA link' do
      gsa_link = section.find('[href="https://www.gsa.gov"]')

      expect(gsa_link.tag_name).to eq('a')
      expect(gsa_link).to have_content('US General Services Administration')
    end

    scenario 'should include Dev Docs link' do
      docs_link = section.find('[href="/documentation"]')

      expect(docs_link.tag_name).to eq('a')
      expect(docs_link).to have_content('Developer Guide')
    end
    scenario 'should include Contact link' do
      gsa_link = section.find('[href="/documentation?destination=/support/#contacting-partner-support"]')

      expect(gsa_link.tag_name).to eq('a')
      expect(gsa_link).to have_content('Contact')
    end
    scenario 'should include Privacy & security link' do
      gsa_link = section.find('[href="https://www.login.gov/policy/"]')

      expect(gsa_link.tag_name).to eq('a')
      expect(gsa_link).to have_content('Privacy & security')
    end
    scenario 'should include Accessibility link' do
      gsa_link = section.find('[href="https://www.login.gov/accessibility/"]')

      expect(gsa_link.tag_name).to eq('a')
      expect(gsa_link).to have_content('Accessibility statement')
    end
  end
end
