# rubocop:disable Metrics/BlockLength
SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=#{1.day.to_i}; includeSubDomains"
  config.x_frame_options = 'SAMEORIGIN'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  form_action = if /login\.gov$/.match?(IdentityConfig.store.idp_url)
                  ["'self'", '*.login.gov']
                else
                  ["'self'", '*.identitysandbox.gov']
                end
  form_action << %w[localhost:3000] if Rails.env.development?
  connect_src = ["'self'", 'https://www.google-analytics.com']
  connect_src << %w[ws://localhost:3036 http://localhost:3036] if Rails.env.development?
  script_src = [
    "'self'",
    '*.newrelic.com',
    '*.nr-data.net',
    'https://dap.digitalgov.gov',
    'https://www.google-analytics.com',
    'https://www.googletagmanager.com',
  ]
  style_src = ["'self'"]
  img_src = ["'self'", 'data:', "https://s3.#{IdentityConfig.store.aws_region}.amazonaws.com"]

  if Rails.env.development?
    script_src.push('*.ssa.gov', 'ajax.googleapis.com')
    style_src.push("'unsafe-inline'", '*.ssa.gov')
    img_src.push('*.ssa.gov')
  end

  config.csp = {
    default_src: ["'self'"],
    frame_src: ["'self'"], # deprecated in CSP 2.0
    child_src: ["'self'"], # CSP 2.0 only; replaces frame_src
    form_action: form_action.flatten,
    connect_src: connect_src.flatten,
    font_src: ["'self'", 'data:'],
    media_src: ["'self'"],
    object_src: ["'none'"],
    base_uri: ["'self'"],
    img_src:,
    script_src:,
    style_src:,
    upgrade_insecure_requests: true,
  }
  # Enable for A11y testing. This allows use of the ANDI tool.
  # Temporarily disabled until we configure pinning. See GitHub issue #1895.
  # config.hpkp = {
  #   report_only: false,
  #   max_age: 60.days.to_i,
  #   include_subdomains: true,
  #   pins: [
  #     { sha256: 'abc' },
  #     { sha256: '123' }
  #   ]
  # }
end
# rubocop:enable Metrics/BlockLength
