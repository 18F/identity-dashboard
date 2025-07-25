require 'rails_helper'

class RedirectsTestRecord < ActiveRecord::Base
  include ActiveModel::Validations
  attr_accessor :redirect_uris, :user_id, :prod_config
  validates_with RedirectsValidator
  def initialize
    @redirect_uris = nil
  end

  def production_ready?
    @prod_config
  end

  def user_id
    @user_id
  end
end

RSpec.describe RedirectsValidator, type: :model do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :logingov_admin) }

  describe 'Login Admin user' do
    it 'allows valid URLs' do
      valid_record = RedirectsTestRecord.new.tap do |model|
        model.user_id = admin.id
        model.prod_config = true
      end

      expect(valid_record).to allow_value('https://good.gov').for(:redirect_uris)
      expect(valid_record).to allow_value('https://good.gov/redirect').for(:redirect_uris)
      expect(valid_record).to allow_value('https://www.good.com/').for(:redirect_uris)
    end
  end
end
