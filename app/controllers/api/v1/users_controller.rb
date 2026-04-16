module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate!, only: :create

      def create
        user = User.create!(user_params)
        token = JwtService.encode({ user_id: user.id })

        render json: { user: user_response(user) }, status: :created
      end

      def show
        raise AuthenticationError, "Forbidden" unless params[:id] == current_user.id

        render json: { user: user_response(current_user) }
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end

      def user_response(user)
        { id: user.id, email: user.email }
      end
    end
  end
end
