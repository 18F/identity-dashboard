# Seeds test users, teams, and service providers for review app environments.
class Seeders::ReviewAppData < Seeders::BaseSeeder
  def seed
    return unless ENV['KUBERNETES_REVIEW_APP']

    logger.info 'Seeding Users'
    create_users

    logger.info 'Seeding Teams'
    create_teams

    logger.info 'Seeding Team Memberships'
    assign_memberships

    logger.info 'Seeding Configurations'
    create_service_providers
    
    logger.info 'Seeded review app data'
  end

  private

  def create_users
    Role::ROLES_NAMES.each do |role_name|
      email = "#{role_name.tr('_', '-')}@gsa.gov"
      next if User.exists?(email: email)

      User.create!(email: email)
      logger.info "Created user: #{email}"
    end
  end

  def create_teams
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
    Role::ROLES_NAMES.each do |role_name|
      user = User.find_by(email: "#{role_name.tr('_', '-')}@gsa.gov")

      # Login.gov staff get added to internal team with their actual role
      if role_name.start_with?('logingov_') && Team.internal_team
        unless TeamMembership.exists?(user: user, team: Team.internal_team)
          TeamMembership.create!(user: user, team: Team.internal_team, role_name: role_name)
          logger.info "Assigned #{user.email} to #{Team.internal_team.name} as #{role_name}"
        end
      end

      # Everyone gets partner roles on the review teams
      partner_role = role_name.sub(/^logingov_/, 'partner_')
      Team.where(name: ['Production Team', 'Sandbox Team']).find_each do |team|
        next if TeamMembership.exists?(user: user, team: team)

        TeamMembership.create!(user: user, team: team, role_name: partner_role)
        logger.info "Assigned #{user.email} to #{team.name} as #{partner_role}"
      end
    end
  end

  def create_service_providers
    base_attrs = {
      user: User.find_by(email: 'logingov-admin@gsa.gov'),
      agency_id: Seeders::AgencySeeder.internal_agency_data[:id],
      attribute_bundle: %w[email],
      help_text: { 'sign_in' => {}, 'sign_up' => {}, 'forgot_password' => {} },
      ial: 1,
      default_aal: 1,
    }

    configs = [
      { name: 'Prod OIDC', prod: true, protocol: :openid_connect_pkce },
      { name: 'Prod SAML', prod: true, protocol: :saml },
      { name: 'Sandbox OIDC', prod: false, protocol: :openid_connect_pkce },
      { name: 'Sandbox SAML', prod: false, protocol: :saml },
    ]

    configs.each do |c|
      issuer = "urn:gov:gsa:reviewapp:#{c[:name].downcase.tr(' ', ':')}"
      next if ServiceProvider.exists?(issuer: issuer)

      sp = ServiceProvider.new(base_attrs.merge(
        issuer: issuer,
        friendly_name: c[:name],
        identity_protocol: c[:protocol],
        prod_config: c[:prod],
        team: Team.find_by(name: c[:prod] ? 'Production Team' : 'Sandbox Team'),
      ))
      if c[:protocol] == :saml
        sp.acs_url = 'https://example.gov/saml/acs'
        sp.return_to_sp_url = 'https://example.gov/return'
      else
        sp.redirect_uris = ['https://example.gov/callback']
      end
      sp.save!
      logger.info "Created service provider: #{c[:name]}"
    end
  end
end
