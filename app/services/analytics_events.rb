# frozen_string_literal: true

# ABC_XYZ -- Keep it Alphabetical! 

module AnalyticsEvents
  # When a user clicks "Create an app"
  def guided_flow_started
    track_event('Guided Flow started')
  end
end
