class BalanceService
  InsufficientFundsError = Class.new(StandardError)

  def self.deposit(user:, amount:)
    ActiveRecord::Base.transaction do
      user.lock!
      user.update!(balance: user.balance + amount)
      user.transactions.create!(kind: :deposit, amount: amount)
    end
    user
  end

  def self.withdraw(user:, amount:)
    ActiveRecord::Base.transaction do
      user.lock!
      raise InsufficientFundsError, "Insufficient funds" unless user.sufficient_funds?(amount)

      user.update!(balance: user.balance - amount)
      user.transactions.create!(kind: :withdraw, amount: amount)
    end
    user
  end

  def self.transfer(sender:, recipient:, amount:)
    raise BadRequestError, "Cannot transfer to yourself" if sender.id == recipient.id

    # Always lock in ascending ID order to prevent deadlocks between concurrent
    # transfers in opposite directions between the same pair of users.
    first, second = [ sender, recipient ].sort_by(&:id)

    ActiveRecord::Base.transaction do
      first.lock!
      second.lock!

      # Reload both so we see their post-lock balances
      sender.reload
      recipient.reload

      raise InsufficientFundsError, "Insufficient funds" unless sender.sufficient_funds?(amount)

      sender.update!(balance: sender.balance - amount)
      recipient.update!(balance: recipient.balance + amount)

      sender.transactions.create!(kind: :transfer, amount: amount, recipient: recipient)
    end
    sender.reload
  end
end
