class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    if ENV['FORCE_USER']
      User.find ENV['FORCE_USER']
    else
      super
    end 
  end 

  def user_signed_in?
    ENV['FORCE_USER'].present? || super
  end
end
