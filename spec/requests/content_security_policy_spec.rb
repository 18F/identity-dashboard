require 'rails_helper'

describe 'Content Security Policy' do
  it 'allows the feedback survey to be embedded in an iframe' do
    get '/'

    csp = response.headers['Content-Security-Policy']
    expect(csp).to include("frame-src 'self' *.qualtrics.com")
  end
end
