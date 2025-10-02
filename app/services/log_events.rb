# frozen_string_literal: true

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
    track_event("extract_#{action}", extracts_params)
  end

  # Generic CrUD logger
  #
  # @param [String] action The controller action context for this save
  # @param [ApplicationRecord] record The record to be saved
  # @return (see EventLogger#track_event)
  def record_save(action, record)
    return if !record

    model_name = record.class.name.downcase
    changes = record.previous_changes.empty? ? record.as_json : {}

    record.previous_changes.each_pair do |k, v|
      if k != 'updated_at'
        if !v.is_a? Array
          changes[k] = v
        else
          changes[k] = {
            old: v[0],
            new: v[1],
          }
        end
      end
    end
    changes[:id] = record.id
    changes.merge!(team_data record) if record.previous_changes[:role_name]
    track_event("#{model_name}_#{action}", changes)
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

    track_event('unauthorized_access_attempt', details)
  end

  # @param [ActionController::UnpermittedParameters] exception
  # @return (see EventLogger#track_event)
  def unpermitted_params_attempt(exception)
    details = {
      message: exception.message,
      params: exception.params,
    }

    track_event('unpermitted_params_attempt', details)
  end

  private

  # @param [#user_id,#group_id] record A record that belongs to a user and a team
  # @return [Hash{Symbol => ApplicationRecord}]
  #   the keys `:team_user` and `:team` with the appropriate record
  def team_data(record)
    {
      team_user: User.find(record[:user_id]).email,
      team: Team.find(record[:group_id]).name,
    }
  end
end
