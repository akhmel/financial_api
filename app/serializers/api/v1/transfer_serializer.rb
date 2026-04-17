class Api::V1::TransferSerializer
  attr_reader :sender, :recipient, :transaction

  def initialize(sender:, recipient:, transaction:)
    @sender = sender
    @recipient = recipient
    @transaction = transaction
  end

  def as_json(*)
    {
      sender: Api::V1::BalanceSerializer.new(sender).as_json,
      recipient: Api::V1::UserSerializer.new(recipient).as_json,
      amount: transaction.amount_cents
    }
  end
end
