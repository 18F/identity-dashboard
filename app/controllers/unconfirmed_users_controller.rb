class UnconfirmedUsersController < ApplicationController
  before_action -> { authorize User }

  def destroy
    count = DeleteUnconfirmedUsers.call
    flash[:success] = "Deleted #{count} unconfirmed #{'users'.pluralize(count)}" if count.positive?
    redirect_to users_path
  end
end

