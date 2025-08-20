class Seeders::Roles < Seeders::AbstractSeeder
  def seed
    Role::ACTIVE_ROLES_NAMES.each do |name, friendly_name|
      unless Role.find_by(name:)
        Role.create(name:, friendly_name:)
        logger.info "#{name} added to roles as #{friendly_name}"
      end
    end
  end
end
