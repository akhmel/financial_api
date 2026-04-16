class BalanceService
  FORMAT = /\A\d+\z/
  MIN_VALUE = 100 # $1.00
  MAX_VALUE = 10_000_000_000 # $100M — adjustable via config if business requires

  def self.deposit(user_id:, amount:, idempotency_key:)
    validate!(amount)
    amount = parse(amount)

    ActiveRecord::Base.transaction do
      guard_idempotency!(idempotency_key)
      user = User.lock.find(user_id)
      user.update!(balance: user.balance + amount)
      user.transactions.create!(kind: :deposit, amount: amount, idempotency_key: idempotency_key)
      user
    end
  end

  def self.withdraw(user_id:, amount:, idempotency_key:)
    validate!(amount)
    amount = parse(amount)

    ActiveRecord::Base.transaction do
      guard_idempotency!(idempotency_key)
      user = User.lock.find(user_id)
      raise InsufficientFundsError, "Insufficient funds" unless user.sufficient_funds?(amount)

      user.update!(balance: user.balance - amount)
      user.transactions.create!(kind: :withdraw, amount: amount, idempotency_key: idempotency_key)
      user
    end
  end

  def self.transfer(sender_id:, recipient_email:, amount:, idempotency_key:)
    validate!(amount)
    amount = parse(amount)

    recipient_id = User.find_by!(email: recipient_email.downcase).id
    raise BadRequestError, "Cannot transfer to yourself" if sender_id == recipient_id

    ActiveRecord::Base.transaction(isolation: :repeatable_read) do
      guard_idempotency!(idempotency_key)
      sender, recipient = User.lock.where(id: [ sender_id, recipient_id ]).order(:id).to_a
      sender, recipient = [ recipient, sender ] if sender.id != sender_id

      raise InsufficientFundsError, "Insufficient funds" unless sender.sufficient_funds?(amount)

      sender.update!(balance: sender.balance - amount)
      recipient.update!(balance: recipient.balance + amount)

      transaction = sender.transactions.create!(kind: :transfer, amount: amount, recipient: recipient, idempotency_key: idempotency_key)

      { sender: sender, recipient: recipient, transaction: transaction }
    end
  end

  class << self
    private

    def guard_idempotency!(key)
      raise BadRequestError, "Idempotency-Key header is required" if key.blank?
      raise DuplicateRequestError, "Duplicate request" if Transaction.exists?(idempotency_key: key)
    end

    def validate!(value)
      raise BadRequestError, "Invalid amount format" unless value.to_s.match?(FORMAT)

      cents = value.to_i
      raise BadRequestError, "Amount must be greater than or equal to #{MIN_VALUE}" unless cents >= MIN_VALUE
      raise BadRequestError, "Amount must be less than or equal to #{MAX_VALUE}" unless cents <= MAX_VALUE
      cents
    end

    def parse(value)
      Money.new(value)
    end
  end
end
