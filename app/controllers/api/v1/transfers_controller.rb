module Api
  module V1
    class TransfersController < ApplicationController
      def create
        result = BalanceService.transfer(
          sender_id: current_user.id,
          recipient_email: params.require(:recipient_email),
          amount: params.require(:amount),
          idempotency_key: idempotency_key
        )

        render json: {
          sender: { email: result[:sender].email, balance: result[:sender].balance_cents },
          recipient: { email: result[:recipient].email, balance: result[:recipient].balance_cents },
          amount: result[:sender].transactions.last.amount_cents
        }, status: :created
      end
    end
  end
end
