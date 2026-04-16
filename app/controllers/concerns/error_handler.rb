module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from AuthenticationError, with: :handle_unauthorized
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_unprocessable
    rescue_from InsufficientFundsError, with: :handle_unprocessable
    rescue_from BadRequestError, with: :handle_bad_request
    rescue_from ActionController::ParameterMissing, with: :handle_bad_request
    rescue_from DuplicateRequestError, with: :handle_conflict
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error
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

  def handle_parse_error(_error)
    render json: { error: "Invalid JSON in request body" }, status: :bad_request
  end
end
