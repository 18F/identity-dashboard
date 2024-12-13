require 'rails_helper'

RSpec.describe SecurityEvent do
  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
  end
end
