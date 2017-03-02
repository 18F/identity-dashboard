class AuthenticatedController < ApplicationController
  before_action :authenticate_user! unless Figaro.env.FORCE_USER
end
