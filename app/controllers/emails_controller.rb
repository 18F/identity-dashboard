class EmailsController < ApplicationController
  before_action -> { authorize User, :login_engineer? }

  def index
    @users = User.all.sort_by(&:domain)
  end
end
