require 'rails_helper'

describe User do
  describe "Associations" do
     it { should have_many(:applications) }
  end

  let(:user) { build(:user) }

  describe "#uuid" do
    it "assigns uuid on create" do
      user.save
      expect(user.uuid).to_not be_nil
      expect(user.uuid).to match(RubyRegex::UUID)
    end
  end
end
