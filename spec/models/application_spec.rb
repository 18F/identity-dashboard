require 'rails_helper'

describe Application do
  describe "Associations" do
     it { should belong_to(:user) }
  end

  let(:application) { build(:application) }

  describe "#issuer" do
    it "assigns uuid on create" do
      application.save
      expect(application.issuer).to_not be_nil
      expect(application.issuer).to match(RubyRegex::UUID)
    end
  end
end
