# Seeds test users, teams, and service providers for review app environments.
class Seeders::ReviewAppData < Seeders::BaseSeeder
  def seed
    return unless Rails.env.development? || ENV['POSTGRES_HOST']&.include?('.review-app')

    create_users
    create_teams
    assign_memberships
    create_service_providers
    logger.info 'Seeded review app data'
  end

  private

  def create_users
    logger.info 'Seeding Users'
    Role::ROLES_NAMES.each do |role_name|
      email = "#{role_name.tr('_', '-')}@gsa.gov"
      next if User.exists?(email: email)

      User.create!(email: email)
      logger.info "Created user: #{email}"
    end
  end

  def create_teams
    logger.info 'Seeding Teams'
    %w[Production Sandbox].each do |env|
      name = "#{env} Team"
      next if Team.exists?(name: name)

      Team.create!(
        name: name,
        agency_id: Seeders::AgencySeeder.internal_agency_data[:id],
        description: "Review app #{env.downcase} team",
      )
      logger.info "Created team: #{name}"
    end
  end

  def assign_memberships
    logger.info 'Seeding Team Memberships'
    Role::ROLES_NAMES.each do |role_name|
      user = User.find_by(email: "#{role_name.tr('_', '-')}@gsa.gov")
      assign_to_internal_team(user, role_name) if role_name.start_with?('logingov_')
      assign_to_review_teams(user, role_name)
    end
  end

  def assign_to_internal_team(user, role_name)
    return unless Team.internal_team
    return if TeamMembership.exists?(user: user, team: Team.internal_team)

    TeamMembership.create!(user: user, team: Team.internal_team, role_name: role_name)
    logger.info "Assigned #{user.email} to #{Team.internal_team.name} as #{role_name}"
  end

  def assign_to_review_teams(user, role_name)
    partner_role = role_name.sub(/^logingov_/, 'partner_')
    Team.where(name: ['Production Team', 'Sandbox Team']).find_each do |team|
      next if TeamMembership.exists?(user: user, team: team)

      TeamMembership.create!(user: user, team: team, role_name: partner_role)
      logger.info "Assigned #{user.email} to #{team.name} as #{partner_role}"
    end
  end

  def create_service_providers
    logger.info 'Seeding Configurations'
    [
      { name: 'Prod OIDC', prod: true, protocol: :openid_connect_pkce },
      { name: 'Prod SAML', prod: true, protocol: :saml },
      { name: 'Sandbox OIDC', prod: false, protocol: :openid_connect_pkce },
      { name: 'Sandbox SAML', prod: false, protocol: :saml },
    ].each { |config| create_service_provider(config) }
  end

  def create_service_provider(config)
    issuer = "urn:gov:gsa:reviewapp:#{config[:name].downcase.tr(' ', ':')}"
    return if ServiceProvider.exists?(issuer: issuer)

    ServiceProvider.create!(service_provider_attrs(config, issuer))
    logger.info "Created service provider: #{config[:name]}"
  end

  def service_provider_attrs(config, issuer)
    attrs = {
      issuer: issuer,
      friendly_name: config[:name],
      identity_protocol: config[:protocol],
      prod_config: config[:prod],
      team: Team.find_by(name: config[:prod] ? 'Production Team' : 'Sandbox Team'),
      user: User.find_by(email: 'logingov-admin@gsa.gov'),
      agency_id: Seeders::AgencySeeder.internal_agency_data[:id],
      attribute_bundle: %w[email],
      help_text: { 'sign_in' => {}, 'sign_up' => {}, 'forgot_password' => {} },
      ial: 1,
      default_aal: 1,
    }
    if config[:protocol] == :saml
      attrs[:acs_url] = 'https://example.gov/saml/acs'
      attrs[:return_to_sp_url] = 'https://example.gov/return'
    else
      attrs[:redirect_uris] = ['https://example.gov/callback']
    end
    attrs
  end
end
