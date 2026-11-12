require 'rails_helper'

describe 'Content Security Policy' do
  it 'allows the feedback survey to be embedded in an iframe' do
    get '/'

    csp = response.headers['Content-Security-Policy']
    expect(csp).to include("frame-src 'self' feedback.gsa.gov")
    expect(csp).to include("child-src 'self' feedback.gsa.gov")
  end
end
