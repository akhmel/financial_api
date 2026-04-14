class ApplicationController < ActionController::API
  include ErrorHandler
  include Authenticatable

  before_action :authenticate!
end
