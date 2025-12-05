class ApplicationRecord < ActiveRecord::Base # :nodoc:
  self.abstract_class = true

  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  def self.find_by_id_or_uuid(identifier)
    if UUID_REGEX.match?(identifier.to_s)
      find_by(uuid: identifier)
    else
      find_by(id: identifier)
    end
  end
end
