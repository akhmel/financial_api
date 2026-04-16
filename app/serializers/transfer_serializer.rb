class TransferSerializer
  def initialize(sender:, recipient:, transaction:)
    @sender = sender
    @recipient = recipient
    @transaction = transaction
  end

  def as_json(*)
    {
      sender: { email: @sender.email, balance: @sender.balance_decimal },
      recipient: { email: @recipient.email },
      amount: @transaction.amount_decimal
    }
  end
end
