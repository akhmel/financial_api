class BalanceSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    { email: @user.email, balance: @user.balance_decimal }
  end
end
