require 'rails_helper'

feature 'External Link Redirects' do
  it 'searches developer doc urls in files' do
    result = `grep -r -l  "developers.login.gov" app/views config/locales`.strip
    expect(result).to be_empty, "Found developers.login.gov links in files:\n#{result}"
  end
end
