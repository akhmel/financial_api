module Api
  module V1
    class BalancesController < ApplicationController
      def show
        render json: { user_id: current_user.id, balance: current_user.balance.to_f }
      end

      def deposit
        BalanceService.deposit(user: current_user, amount: amount_param, idempotency_key: idempotency_key)

        render json: { user_id: current_user.id, balance: current_user.balance.to_f }
      end

      def withdraw
        BalanceService.withdraw(user: current_user, amount: amount_param, idempotency_key: idempotency_key)

        render json: { user_id: current_user.id, balance: current_user.balance.to_f }
      end

      private

      def amount_param
        AmountValidator.parse!(params.require(:amount))
      end
    end
  end
end
