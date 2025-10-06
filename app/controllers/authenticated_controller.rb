class AuthenticatedController < ApplicationController # :nodoc:
  before_action :authenticate_user!
end
