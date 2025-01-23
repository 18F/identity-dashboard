# frozen_string_literal: true

# ABC_XYZ -- Keep it Alphabetical!

module AnalyticsEvents
  # When a user clicks "Create an app"
  def sp_config_created
    track_event('sp_config_created')
  end
end
