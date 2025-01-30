Rails.application.config.after_initialize do
  Role::ACTIVE_ROLES.each do |name, friendly_name|
    if !Role.find_by(name:)
      Role.create(name:, friendly_name:)
      puts "#{name} added to roles as #{friendly_name}"
    end
  end
end
