module Api
  module V1
    class BalancesController < ApplicationController
      def show
        render json: current_user, serializer: Api::V1::BalanceSerializer
      end

      def deposit
        user = BalanceService.deposit(user_id: current_user.id, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: user, serializer: Api::V1::BalanceSerializer
      end

      def withdraw
        user = BalanceService.withdraw(user_id: current_user.id, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: user, serializer: Api::V1::BalanceSerializer
      end
    end
  end
end
