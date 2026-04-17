class Api::V1::TransactionSerializer < ActiveModel::Serializer
  attributes :amount

  def amount
    object.amount_cents
  end
end
