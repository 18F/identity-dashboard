require 'rails_helper'

describe 'Content Security Policy' do
  it 'allows the feedback survey to be embedded in an iframe' do
    get '/'

    csp = response.headers['Content-Security-Policy']
    expect(csp).to include("child-src 'self' *.qualtrics.com feedback.gsa.gov")
  end

  it 'allows the feedback survey form to be submitted to feedback.gsa.gov' do
    get '/'

    csp = response.headers['Content-Security-Policy']
    expect(csp).to match(/form-action [^;]*feedback\.gsa\.gov/)
  end
end
