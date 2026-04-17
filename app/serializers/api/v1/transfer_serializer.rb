class Api::V1::TransferSerializer
  attr_reader :sender, :recipient, :transaction

  def initialize(sender:, recipient:, transaction:)
    @sender = sender
    @recipient = recipient
    @transaction = transaction
  end

  def as_json(*)
    {
      sender: Api::V1::BalanceSerializer.new(sender),
      recipient: Api::V1::UserSerializer.new(recipient), #no balance here due to security reasons
      transfered: Api::V1::TransactionSerializer.new(transaction)
    }
  end
end
