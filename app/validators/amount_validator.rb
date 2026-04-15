class AmountValidator
  def self.parse!(value)
    amount = BigDecimal(value.to_s)
    raise BadRequestError, "Amount must be positive" unless amount.positive?

    amount
  rescue ::ArgumentError
    raise BadRequestError, "Invalid amount"
  end
end
