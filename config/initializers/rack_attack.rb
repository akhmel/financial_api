class Rack::Attack
  ### Throttle login attempts by IP ###
  # Allow 10 login attempts per minute per IP
  throttle("logins/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/api/v1/session" && req.post?
  end

  # Allow 5 login attempts per minute per email (body param)
  throttle("logins/email", limit: 5, period: 60) do |req|
    if req.path == "/api/v1/session" && req.post?
      # Parse body to extract email; fall back gracefully if not present
      body = req.body.read
      req.body.rewind
      params = JSON.parse(body) rescue {}
      params.dig("session", "email")&.downcase&.presence
    end
  end

  ### Throttle registration by IP ###
  throttle("registrations/ip", limit: 10, period: 3600) do |req|
    req.ip if req.path == "/api/v1/users" && req.post?
  end

  ### Throttle financial operations per authenticated user (by IP as proxy) ###
  throttle("transfers/ip", limit: 30, period: 60) do |req|
    req.ip if req.path == "/api/v1/transfers" && req.post?
  end

  throttle("deposits/ip", limit: 30, period: 60) do |req|
    req.ip if req.path == "/api/v1/balance/deposit" && req.post?
  end

  throttle("withdrawals/ip", limit: 30, period: 60) do |req|
    req.ip if req.path == "/api/v1/balance/withdraw" && req.post?
  end

  ### Return 429 JSON responses when throttled ###
  self.throttled_responder = lambda do |env|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Too many requests. Please try again later." }.to_json ]
    ]
  end
end
