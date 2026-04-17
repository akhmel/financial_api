class Api::V1::BalanceSerializer < ActiveModel::Serializer
  attributes :email, :balance

  def balance
    object.balance_cents
  end
end
