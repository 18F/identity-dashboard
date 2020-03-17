class HomeController < ApplicationController
  def index
    render :index and return unless user_signed_in?

    includes = %i[users service_providers agency]
    @teams = if current_user.admin?
               Team.includes(*includes).all
             else
               current_user.teams.includes(*includes).all
             end

    render 'home/authenticated/index'
  end
end
