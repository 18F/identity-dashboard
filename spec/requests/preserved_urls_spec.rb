require 'rails_helper'

describe 'Preserved URLs' do
  describe 'groups URL schema' do
    it 'redirects to the Teams route' do
      get '/groups/1'

      expect(response.status).to eq(301)
      expect(response.location).to eq('http://www.example.com/teams/1')
    end
  end
end
