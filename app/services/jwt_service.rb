class JwtService
  SECRET = ENV.fetch("JWT_SECRET")
  ALGORITHM = "HS256"

  def self.encode(payload, exp: 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: ALGORITHM)
    decoded.first.with_indifferent_access
  rescue JWT::DecodeError => e
    raise AuthenticationError, e.message
  end
end
