module ModelChanges
  def changes_to_log(record)
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
    changes['id'] = record.id
    changes
  end
end
