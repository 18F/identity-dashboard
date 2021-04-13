require 'rails_helper'

RSpec.describe SecurityEvent do
  describe 'Associations' do
    it { should belong_to(:user) }
  end
end
