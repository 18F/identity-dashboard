class HomeController < ApplicationController
  def index
    redirect_to service_providers_path if user_signed_in?
  end
end
