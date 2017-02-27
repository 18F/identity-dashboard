class AuthenticatedController < ApplicationController
  before_action :authenticate_user! unless Figaro.env.force_user
end
