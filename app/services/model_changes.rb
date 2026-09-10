# A module to extract changes from ActiveRecord models for logging purposes.
# This is used in controllers to log changes to models like ServiceProvider, Team, and
# TeamMembership.
# It captures the pending changes to be made to a record and formats them into a hash
# suitable for logging. This is designed to be called before database operations.
module ModelChanges
  def changes_to_log(record)
    # Use pending changes (before save) instead of previous_changes (after save)
    # For new records with no changes yet, fall back to as_json
    pending_changes = record.changes
    changes = pending_changes.empty? ? record.as_json : {}

    pending_changes.each_pair do |k, v|
      next if k == 'updated_at'

      changes[k] = {
        'old' => sanitize_for_log(v[0]),
        'new' => sanitize_for_log(v[1]),
      }
    end

    changes['id'] = record.id
    changes
  end

  private

  # An attribute's pending value can be arbitrary user-supplied content (e.g. the raw bytes
  # of an uploaded cert file) that isn't valid UTF-8, which would otherwise raise when the
  # logger tries to JSON-encode it.
  def sanitize_for_log(value)
    case value
    when String
      value = value.dup.force_encoding('UTF-8') unless value.encoding == Encoding::UTF_8
      value.valid_encoding? ? value : value.scrub
    when Array
      value.map { |v| sanitize_for_log(v) }
    else
      value
    end
  end
end
