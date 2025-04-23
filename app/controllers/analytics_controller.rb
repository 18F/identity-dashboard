require 'portal/constants'

class AnalyticsController < ApplicationController
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  include Portal::Constants

  # GET /analytics
  # GET /analytics.json
  # GET /analytics.xml
  #
  # This action serves the analytics home page.
  #
  # @return [void]
  #
  # @example
  #   GET /analytics
  #

  def show
  end
end
