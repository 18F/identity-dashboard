class HomeController < ApplicationController
  def index
    redirect_to teams_path if user_signed_in?
  end
end
