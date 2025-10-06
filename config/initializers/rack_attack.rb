class Rack::Attack # :nodoc:
  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  # Safelist localhost when running the test suite, since the test suite will otherwise fail
  if Rails.env.test?
    throttle('req/ip', limit: 100, period: 1.minute) do |req|
      req.ip if req.ip != '127.0.0.1' && req.ip != '::1'
    end
  else
    throttle('req/ip', limit: 100, period: 1.minute) do |req|
      req.ip # unless req.path.start_with?('/assets')
    end
  end

  ### Prevent Brute-Force Login Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.

  # Throttle POST requests to /login by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('auth/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == '/auth/logindotgov' && req.post?
  end

  ### Basic Auth Attacks
  #
  # After 5 requests with the same user account within 1 minute,
  # block all requests from that IP for 1 hour.
  blocklist('suspicious basic auth usage') do |req|
    if req.env['HTTP_AUTHORIZATION']
      token_params = ActionController::HttpAuthentication::Token.token_params_from(
        req.env['HTTP_AUTHORIZATION'],
      ).to_h
      email = token_params['email']
      Allow2Ban.filter(req.ip, maxretry: 5, findtime: 1.minute, bantime: 1.hour) do
        email.present?
      end
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # self.throttled_responder = lambda do |env|
  #  [ 503,  # status
  #    {},   # headers
  #    ['']] # body
  # end
  # self.blocklisted_responder = lambda do |req|
  # end
end

# Logging
ActiveSupport::Notifications.subscribe(
  'throttle.rack_attack',
) do |_name, start, finish, req_id, payload|
  request = payload[:request]

  EventLogger.new(request:).track_event(
    'activity_throttled',
    {
      matched: request.env['rack.attack.matched'],
      start: start,
      finish: finish,
      req_id: req_id,
      details: request.env['rack.attack.match_data'],
    },
  )
end

ActiveSupport::Notifications.subscribe(
  'blocklist.rack_attack',
) do |_name, start, finish, req_id, payload|
  request = payload[:request]
  email = ActionController::HttpAuthentication::Token.token_params_from(
    request.env['HTTP_AUTHORIZATION'],
  ).to_h['email']

  EventLogger.new(request:).track_event(
    'blocklisted',
    {
      matched: request.env['rack.attack.matched'],
      start: start,
      finish: finish,
      req_id: req_id,
      ip: request.ip,
      email: email,
    },
  )
end
