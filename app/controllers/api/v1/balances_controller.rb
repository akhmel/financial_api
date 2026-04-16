module Api
  module V1
    class BalancesController < ApplicationController
      def show
        render json: { email: current_user.email, balance: current_user.balance_cents }
      end

      def deposit
        user = BalanceService.deposit(user_id: current_user.id, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: { email: user.email, balance: user.balance_cents }
      end

      def withdraw
        user = BalanceService.withdraw(user_id: current_user.id, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: { email: user.email, balance: user.balance_cents }
      end
    end
  end
end
