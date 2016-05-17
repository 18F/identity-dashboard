class ApplicationController < ActionController::Base
  include Pundit

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :render_401

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

  def new_session_path(scope)
    new_user_session_path
  end

  def render_401
    render file: 'public/401.html', status: 401
  end
end
