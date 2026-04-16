module Api
  module V1
    class BalancesController < ApplicationController
      def show
        render json: BalanceSerializer.new(current_user)
      end

      def deposit
        user = BalanceService.deposit(user_id: current_user.id, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: BalanceSerializer.new(user)
      end

      def withdraw
        user = BalanceService.withdraw(user_id: current_user.id, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: BalanceSerializer.new(user)
      end
    end
  end
end
