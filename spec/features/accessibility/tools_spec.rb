require 'rails_helper'
require 'axe-rspec'

feature 'Tools views', :js do

  context 'saml_request views' do
    # there is currently no restrictions for viewing the saml authentication request tool
    context 'without input' do
      scenario 'is accessible' do
        visit tools_saml_request_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'bad input' do
      scenario 'warning is accessible' do
        visit tools_saml_request_path
        fill_in 'Auth URL', with: 'bad input'
        click_on 'Validate'

        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'good SAML auth input' do
      let(:auth) do
        'fVJdj9MwEHxH4j9YlspbPns0qWlaVS1IlQ6E7oAHXtDGce4sHNt4N+Xu3+ME9XQS4l7tmdnZmd3sHgbDziqgdrbhRZrz3fb1qw3CYLzYj3Rvb9SvUSGxCLQopo+Gj8EKB6hRWBgUCpLidv/xWpRpLgBRBYpy/BnFv8zxwZGTznC2v7APzuI4qHCrwllL9fXmuuH3RB5FlqFPtaVUd8qSpkcE27XuIb1z5wyi5WyamEkwpgX5czdSXzeL9+VifVisl29g8O+Mg6bg7Bj30hZo3v0irrsX1L3+Kz6N4ex0bPiPVS+haqs6WUNbJVfr/m3SdqsyKWp5VSuQS7mqIxRxVCeLBJYaXuZFleRlUi6/lLlYrkRRfefs26WGGAmPLTA29yBmbthOAUYT4g7hKbk0JtdrE+NELxCdCKANJtH/JnvOfRLz4lNM/3T87IyWj2xvjPt9CApINZzCqDj74MIA9P++irSYX3SX9DNU+Mk3UoyLZ9PxZP9ez/YP'
      end

      scenario 'is accessible' do
        visit tools_saml_request_path
        fill_in 'Auth URL', with: auth

        click_on 'Validate'

        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end
end
