# frozen_string_literal: true

# ABC_XYZ -- Keep it Alphabetical!
# Security and analytics events are separated alphabetically
# status should be 'SUCCESS', 'FAILURE', or HTTP status

module LogEvents
  # Generic CrUD logger
  def record_save(record)
    model_name = record.class.name.downcase
    op_name = record.previous_changes == {} ?
      'deleted' :
       record.created_at == record.updated_at ?
        'created' :
        'updated'
    changes = record.previous_changes.filter do |k, v|
      !k.match('updated_at')
    end
    track_event("#{model_name}_#{op_name}", changes)
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
