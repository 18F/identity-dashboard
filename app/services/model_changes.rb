# A module to extract changes from ActiveRecord models for logging purposes.
# This is used in controllers to log changes to models like ServiceProvider, Team, and TeamMembership.
# It captures the previous changes made to a record and formats them into a hash suitable for logging.
module ModelChanges
  def changes_to_log(record)
    changes = record.previous_changes.empty? ? record.as_json : {}

    record.previous_changes.each_pair do |k, v|
      next if k == 'updated_at'

      changes[k] = {
        'old' => v[0],
        'new' => v[1],
      }
    end

    changes['id'] = record.id
    changes
  end
end
