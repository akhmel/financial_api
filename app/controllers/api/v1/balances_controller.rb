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
        amount = BigDecimal(params.require(:amount).to_s)
        raise BadRequestError, "Amount must be positive" unless amount.positive?

        amount
      rescue ::ArgumentError
        raise BadRequestError, "Invalid amount"
      end

      def idempotency_key
        request.headers["Idempotency-Key"]
      end
    end
  end
end
