# Base Controller for Authenticated user
class AuthenticatedController < ApplicationController
  before_action :authenticate_user!
end
