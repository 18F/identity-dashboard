# frozen_string_literal: true

# ABC_XYZ -- Keep it Alphabetical!
# Security and analytics events are separated alphabetically

module LogEvents
  # When a user clicks "Create an app"
  def sp_config_created
    track_event('sp_config_created')
  end

  def team_role_updated(controller:, membership:)
    track_event('team_role_updated', {
      current_user: controller.current_user.uuid,
      team_user: membership.user.email,
      team: membership.team.name,
      role: {
        new: membership.role_name,
        old: membership.role_name_was,
      },
    })
  end
end
