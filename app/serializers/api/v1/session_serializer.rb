class Api::V1::SessionSerializer
  attr_reader :token

  def initialize(token:)
    @token = token
  end

  def as_json(*)
    { token: token }
  end
end
