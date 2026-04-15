class ApplicationController < ActionController::API
  include ErrorHandler
  include Authenticatable

  before_action :authenticate!

  private

  def idempotency_key
    request.headers["Idempotency-Key"]
  end
end
