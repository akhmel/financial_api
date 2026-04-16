class MoneyValidator
  FORMAT = /\A\d+\z/
  MIN_VALUE = 100 # $1.00
  MAX_VALUE = 10_000_000_000 # $100M — adjustable via config if business requires

  def self.validate!(value)
    raise BadRequestError, "Invalid amount format" unless value.to_s.match?(FORMAT)

    cents = value.to_i
    raise BadRequestError, "Amount must be greater than or equal to #{MIN_VALUE}" unless cents >= MIN_VALUE
    raise BadRequestError, "Amount must be less than or equal to #{MAX_VALUE}" unless cents <= MAX_VALUE
    cents
  end

  def self.parse!(value)
    Money.new(validate!(value))
  end
end
