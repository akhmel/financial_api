module Api
  module V1
    class TransfersController < ApplicationController
      def create
        recipient = User.find(params.require(:recipient_id))

        BalanceService.transfer(
          sender: current_user,
          recipient: recipient,
          amount: amount_param
        )

        render json: {
          sender: { id: current_user.id, balance: current_user.balance.to_f },
          recipient: { id: recipient.id },
          amount: amount_param.to_f
        }, status: :created
      end

      private

      def amount_param
        amount = BigDecimal(params.require(:amount).to_s)
        raise BadRequestError, "Amount must be positive" unless amount.positive?

        amount
      rescue ::ArgumentError
        raise BadRequestError, "Invalid amount"
      end
    end
  end
end
