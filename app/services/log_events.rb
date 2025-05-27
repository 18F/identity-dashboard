# frozen_string_literal: true

# ABC_XYZ -- Keep it Alphabetical!
# Security and analytics events are separated alphabetically
# status should be 'SUCCESS', 'FAILURE', or HTTP status

module LogEvents
  # Generic CrUD logger
  def record_save(action, record)
    model_name = record.class.name.downcase
    changes = {}

    record.previous_changes.each_pair do |k,v|
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

    track_event("#{model_name}_#{action}", changes)
  end

  # When a user clicks "Create an app"
  def sp_config_created
    track_event('sp_config_created')
  end

  def team_role_updated(membership:)
    track_event('team_role_updated', {
      team_user: membership.user.email,
      team: membership.team.name,
      role: {
        new: membership.role_name,
        old: membership.role_name_was,
      },
    })
  end
end
