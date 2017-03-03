class ApplicationController < ActionController::Base
  include Pundit

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :render_401

  def new_session_path(_scope)
    new_user_session_path
  end

  def render_401
    render file: 'public/401.html', status: 401
  end
end
