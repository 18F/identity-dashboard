require 'rails_helper'

describe ServiceProviderIssuerParser do
  describe '#parse' do
    it 'returns a dictionary of substrings for a valid issuer' do
      issuer = 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:gsa:cool-app'

      parser_data = ServiceProviderIssuerParser.new(issuer).parse

      expect(parser_data[:department]).to eq('gsa')
      expect(parser_data[:app]).to eq('cool-app')
    end

    it 'returns a dictionary of nils for an invalid issuer' do
      issuer = 'parse me, i dare you >:)'

      parser_data = ServiceProviderIssuerParser.new(issuer).parse

      expect(parser_data[:department]).to be_nil
      expect(parser_data[:app]).to be_nil
    end
  end
end
