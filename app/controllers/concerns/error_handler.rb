module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from AuthenticationError, with: :handle_unauthorized
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_unprocessable
    rescue_from BalanceService::InsufficientFundsError, with: :handle_unprocessable
    rescue_from BadRequestError, with: :handle_bad_request
    rescue_from ActionController::ParameterMissing, with: :handle_bad_request
    rescue_from BalanceService::DuplicateRequestError, with: :handle_conflict
  end

  private

  def handle_unauthorized(error)
    render json: { error: error.message }, status: :unauthorized
  end

  def handle_not_found(_error)
    render json: { error: "Not found" }, status: :not_found
  end

  def handle_unprocessable(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def handle_bad_request(error)
    render json: { error: error.message }, status: :bad_request
  end

  def handle_conflict(error)
    render json: { error: error.message }, status: :conflict
  end
end
