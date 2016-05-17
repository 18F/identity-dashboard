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

  describe "#after_create" do
    it 'sends welcome email' do
      ActionMailer::Base.deliveries.clear
      expect(ActionMailer::Base.deliveries.count).to eq(0)
      user.save
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq(I18n.t('dashboard.mailer.welcome.subject'))
    end
  end
end
