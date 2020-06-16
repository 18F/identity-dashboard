class UnconfirmedUsersController < ApplicationController
  def delete
    count = CleanUsersService.call
    flash[:success] = "Deleted #{count} unconfirmed #{'users'.pluralize(count)}" if count.positive?
    redirect_to users_path
  end
end

