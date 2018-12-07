class EmailsController < ApplicationController
  before_action -> { authorize User }

  def index
    @users = User.all.sort_by(&:domain)
  end
end
