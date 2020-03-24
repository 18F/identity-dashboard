class HomeController < ApplicationController
  def index
    render :index and return unless user_signed_in?

    includes = %i[users service_providers agency]
    @teams = current_user.teams.includes(*includes).all

    render 'home/authenticated/index'
  end
end
