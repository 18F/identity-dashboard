class EmailsController < ApplicationController
  before_action -> { authorize(User, :manage_users?) }

  def index
    @users = User.all.sort_by(&:domain)
  end
end
