module Api
  module V1
    class TransfersController < ApplicationController
      def create
        recipient = User.find(params.require(:recipient_id))
        amount = params.require(:amount)

        BalanceService.transfer(
          sender: current_user,
          recipient: recipient,
          amount: amount,
          idempotency_key: idempotency_key
        )

        render json: {
          sender: { id: current_user.id, balance: current_user.balance_cents },
          recipient: { id: recipient.id },
          amount: amount.to_i
        }, status: :created
      end
    end
  end
end
