# frozen_string_literal: true

# ABC_XYZ -- Keep it Alphabetical!
# Security and analytics events are separated alphabetically
# status should be 'SUCCESS', 'FAILURE', or HTTP status

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
end
