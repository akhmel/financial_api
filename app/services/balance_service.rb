class BalanceService
  def self.deposit(user_id:, amount:, idempotency_key:)
    amount = MoneyValidator.parse!(amount)

    guard_idempotency!(idempotency_key)

    ActiveRecord::Base.transaction do
      user = User.lock.find(user_id)
      user.update!(balance: user.balance + amount)
      user.transactions.create!(kind: :deposit, amount: amount, idempotency_key: idempotency_key)
      user
    end
  end

  def self.withdraw(user_id:, amount:, idempotency_key:)
    amount = MoneyValidator.parse!(amount)

    guard_idempotency!(idempotency_key)

    ActiveRecord::Base.transaction do
      user = User.lock.find(user_id)
      raise InsufficientFundsError, "Insufficient funds" unless user.sufficient_funds?(amount)

      user.update!(balance: user.balance - amount)
      user.transactions.create!(kind: :withdraw, amount: amount, idempotency_key: idempotency_key)
      user
    end
  end

  def self.transfer(sender_id:, recipient_email:, amount:, idempotency_key:)
    amount = MoneyValidator.parse!(amount)

    recipient_id = User.find_by!(email: recipient_email.downcase).id
    raise BadRequestError, "Cannot transfer to yourself" if sender_id == recipient_id

    guard_idempotency!(idempotency_key)

    ActiveRecord::Base.transaction(isolation: :repeatable_read) do
      sender, recipient = User.lock.where(id: [ sender_id, recipient_id ]).order(:id).to_a
      sender, recipient = [ recipient, sender ] if sender.id != sender_id

      raise InsufficientFundsError, "Insufficient funds" unless sender.sufficient_funds?(amount)

      sender.update!(balance: sender.balance - amount)
      recipient.update!(balance: recipient.balance + amount)

      sender.transactions.create!(kind: :transfer, amount: amount, recipient: recipient, idempotency_key: idempotency_key)

      { sender: sender, recipient: recipient }
    end
  end

  def self.guard_idempotency!(key)
    raise BadRequestError, "Idempotency-Key header is required" if key.blank?
    raise DuplicateRequestError, "Duplicate request" if Transaction.exists?(idempotency_key: key)
  end
  private_class_method :guard_idempotency!
end
