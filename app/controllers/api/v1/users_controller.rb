module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate!, only: :create

      def create
        user = User.create!(user_params)
        render json: user, serializer: UserSerializer, status: :created
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
