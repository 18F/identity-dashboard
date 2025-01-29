ACTIVE_ROLES = {
  :login_admin => 'Login.gov Admin',
  :partner_admin => 'Partner Admin',
  :partner_dev => 'Partner Developer',
  :partner_readonly => 'Partner Readonly',
}

Rails.application.config.after_initialize do
  ACTIVE_ROLES.each do |name, friendly_name|
    if !Role.find_by(name:)
      Role.create(name:, friendly_name:)
      puts "#{name} added to roles as #{friendly_name}"
    end
  end
end
