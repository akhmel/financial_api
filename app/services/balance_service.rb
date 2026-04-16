class BalanceService
  def self.deposit(user:, amount:, idempotency_key:)
    amount = MoneyValidator.parse!(amount)

    guard_idempotency!(idempotency_key)

    ActiveRecord::Base.transaction do
      user.lock!
      user.update!(balance: user.balance + amount)
      user.transactions.create!(kind: :deposit, amount: amount, idempotency_key: idempotency_key)
    end

    user
  end

  def self.withdraw(user:, amount:, idempotency_key:)
    amount = MoneyValidator.parse!(amount)

    guard_idempotency!(idempotency_key)

    ActiveRecord::Base.transaction do
      user.lock!
      raise InsufficientFundsError, "Insufficient funds" unless user.sufficient_funds?(amount)

      user.update!(balance: user.balance - amount)
      user.transactions.create!(kind: :withdraw, amount: amount, idempotency_key: idempotency_key)
    end
    user
  end

  def self.transfer(sender:, recipient:, amount:, idempotency_key:)
    amount = MoneyValidator.parse!(amount)

    raise BadRequestError, "Cannot transfer to yourself" if sender.id == recipient.id

    guard_idempotency!(idempotency_key)

    first, second = [ sender, recipient ].sort_by(&:id)

    ActiveRecord::Base.transaction(isolation: :repeatable_read) do
      first.lock!
      second.lock!

      sender.reload
      recipient.reload

      raise InsufficientFundsError, "Insufficient funds" unless sender.sufficient_funds?(amount)

      sender.update!(balance: sender.balance - amount)
      recipient.update!(balance: recipient.balance + amount)

      sender.transactions.create!(kind: :transfer, amount: amount, recipient: recipient, idempotency_key: idempotency_key)
    end

    sender.reload
    sender
  end

  def self.guard_idempotency!(key)
    raise BadRequestError, "Idempotency-Key header is required" if key.blank?
    raise DuplicateRequestError, "Duplicate request" if Transaction.exists?(idempotency_key: key)
  end
  private_class_method :guard_idempotency!
end
