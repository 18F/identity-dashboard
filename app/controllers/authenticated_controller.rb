class AuthenticatedController < ApplicationController
  before_action :authenticate_user! unless ENV['FORCE_USER']
end
