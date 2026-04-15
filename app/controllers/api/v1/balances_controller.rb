module Api
  module V1
    class BalancesController < ApplicationController
      def show
        render json: { user_id: current_user.id, balance: current_user.balance_cents }
      end

      def deposit
        BalanceService.deposit(user: current_user, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: { user_id: current_user.id, balance: current_user.balance_cents }
      end

      def withdraw
        BalanceService.withdraw(user: current_user, amount: params.require(:amount), idempotency_key: idempotency_key)

        render json: { user_id: current_user.id, balance: current_user.balance_cents }
      end
    end
  end
end
