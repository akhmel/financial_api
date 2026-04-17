module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate!

      def create
        user = User.find_by(email: params.dig(:session, :email)&.downcase)

        unless user&.authenticate(params.dig(:session, :password))
          raise AuthenticationError, "Invalid email or password"
        end

        token = JwtService.encode({ user_id: user.id })
        render json: SessionSerializer.new(token: token), status: :created
      end
    end
  end
end
