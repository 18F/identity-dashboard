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
