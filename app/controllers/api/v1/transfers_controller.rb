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

        render json: TransferSerializer.new(**result), status: :created
      end
    end
  end
end
