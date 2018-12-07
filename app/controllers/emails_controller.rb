class EmailsController < ApplicationController
  before_action -> { authorize User }

  def index
    @users = User.all.sort {|a, b| a.domain <=> b.domain}
  end
end
