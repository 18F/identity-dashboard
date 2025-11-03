# frozen_string_literal: true

# Events that will trigger a log
#
# If you add or update calls to `track_event`, also update the documentation for events.
# Currently, that documentation is at:
# https://docs.google.com/spreadsheets/d/1LN9fBnYCYMgJeHlxXwdt47OE0xdIHpI0eoXEimmv7Ak/edit
#
# ABC_XYZ -- Keep it Alphabetical!
module LogEvents
  # @param [String] action The controller action context for this request
  # @param [ActionController::Parameters] extracts_params All parameters for Extract
  # @return (see EventLogger#track_event)
  def extraction_request(action, extracts_params)
    track_event("partner_portal_extract_#{action}", extracts_params)
  end

  # Log when a service provider is created
  # @param changes [Hash] The changes to log
  def sp_created(changes:)
    track_event('partner_portal_sp_created', changes:)
  end

  # Log when a service provider is destroyed
  # @param [Hash] changes The changes to log
  def sp_destroyed(changes:)
    track_event('partner_portal_sp_destroyed', changes:)
  end

  # Log when a service provider is updated
  # @param [Hash] changes The changes to log
  def sp_updated(changes:)
    track_event('partner_portal_sp_updated', changes:)
  end

  # Log when a team is created
  # @param [Hash] changes The changes to log
  def team_created(changes:)
    track_event('partner_portal_team_created', changes:)
  end

  # Log when a team is destroyed
  # @param [Hash] changes The changes to log
  def team_destroyed(changes:)
    track_event('partner_portal_team_destroyed', changes:)
  end

  # Log when a team membership is created
  # @param [Hash] changes The changes to log
  def team_membership_created(changes:)
    track_event('partner_portal_team_membership_created', changes:)
  end

  # Log when a team membership is destroyed
  # @param [Hash] changes The changes to log
  def team_membership_destroyed(changes:)
    track_event('partner_portal_team_membership_destroyed', changes:)
  end

  # Log when a team membership changes
  # @param [Hash] changes The changes to log
  def team_membership_updated(changes:)
    track_event('partner_portal_team_membership_updated', changes:)
  end

  # Log when a team is updated
  # @param [Hash] changes The changes to log
  def team_updated(changes:)
    track_event('partner_portal_team_updated', changes:)
  end

  # @param [Pundit::NotAuthorizedError] exception
  # @return (see EventLogger#track_event)
  def unauthorized_access_attempt(exception)
    details = {
      message: exception.message,
      query: exception.query.to_s,
      record: exception.record.is_a?(Class) ?
        exception.record.name :
        exception.record.class.name,
      policy: exception.policy.class.name,
    }

    track_event('partner_portal_unauthorized_access_attempt', details)
  end

  # @param [ActionController::UnpermittedParameters] exception
  # @return (see EventLogger#track_event)
  def unpermitted_params_attempt(exception)
    details = {
      message: exception.message,
      params: exception.params,
    }

    track_event('partner_portal_unpermitted_params_attempt', details)
  end

  # Log when a user is created
  # @param [Hash] changes The changes to log
  def user_created(changes:)
    track_event('partner_portal_user_created', changes:)
  end

  # Log when a user is destroyed
  # @param [Hash] changes The changes to log
  def user_destroyed(changes:)
    track_event('partner_portal_user_destroyed', changes:)
  end

  # Log when a user clicks the back button
  # @params [String] Name of step that back button was pressed on
  def wizard_back_pressed(step_name:)
    track_event('partner_portal_wizard_back_pressed', step_name:)
  end

  # Analytics log when a partner selects Next in the Guided Flow Wizard
  # @param step_name [String] The name of the submitted step
  def wizard_step_updated(step_name:)
    track_event('partner_portal_wizard_step_updated', step_name:)
  end
end
