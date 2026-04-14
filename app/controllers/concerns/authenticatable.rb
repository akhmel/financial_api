module Authenticatable
  extend ActiveSupport::Concern

  private

  def authenticate!
    token = extract_token
    raise AuthenticationError, "Missing token" if token.blank?

    payload = JwtService.decode(token)
    @current_user = User.find(payload[:user_id])
  rescue ActiveRecord::RecordNotFound
    raise AuthenticationError, "Invalid token: user not found"
  end

  def current_user
    @current_user
  end

  def extract_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end
end
