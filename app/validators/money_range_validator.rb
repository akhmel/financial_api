class MoneyRangeValidator
  FORMAT = /\A\d+\z/
  MIN_VALUE = 100 # $1.00
  MAX_VALUE = 10_000_000_000 # $100M — adjustable via config if business requires

  def self.validate!(value)
    raise BadRequestError, "Invalid amount format" unless value.to_s.match?(FORMAT)
    raise BadRequestError, "Amount must be greater than or equal to #{MIN_VALUE}" unless value.to_i >= MIN_VALUE
    raise BadRequestError, "Amount must be less than or equal to #{MAX_VALUE}" unless value.to_i <= MAX_VALUE
    Money.new(value)
  end
end
