class ApplicationController < ActionController::Base
  include Pundit

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :render_401

  def current_user
    if Figaro.env.FORCE_USER
      User.find(Figaro.env.FORCE_USER)
    else
      super
    end
  end

  def user_signed_in?
    Figaro.env.FORCE_USER.present? || super
  end

  def new_session_path(_scope)
    new_user_session_path
  end

  def render_401
    render file: 'public/401.html', status: 401
  end
end
