# frozen_string_literal: true

# ABC_XYZ -- Keep it Alphabetical!

module LogEvents
  # Generic CrUD logger
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

  def team_data(record)
    {
      team_user: User.find(record[:user_id]).email,
      team: Team.find(record[:group_id]).name,
    }
  end

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

  def unpermitted_params_attempt(exception)
    details = {
      message: exception.message,
      params: exception.params.join(', '),
      record: self.request.path.gsub('_', '').match(/^\/?([a-zA-Z]+)/)[1],
    }

    track_event('unpermitted_params_attempt', details)
  end
#   def exception(exception, event_name)
#     details = { detailed_message: exception.detailed_message }

#     if event_name == 'unauthorized'
#       details.merge!({ method: exception.query.to_s })
#       model_name = exception.record.is_a?(Class) ?
#         exception.record.name.downcase :
#         exception.record.class.name.downcase
#     elsif event_name == 'unpermitted_params'
#       details.merge!({ params: exception.params.join(', ') })
#       model_name = self.request.path.gsub('_', '').match(/^\/?([a-zA-Z_]+)/)[1]
#     else
#       model_name = 'unknown'
#       event_name = 'exception'
#     end
# binding.pry
#     track_event("#{model_name}_#{event_name}", details)
#   end
end
