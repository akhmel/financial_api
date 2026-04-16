require "rails_helper"

RSpec.describe BalanceService do
  let(:user) { create(:user, balance: 0) }

  describe "amount validation" do
    def deposit(amount)
      BalanceService.deposit(user_id: user.id, amount: amount, idempotency_key: SecureRandom.uuid)
    end

    context "with valid amounts" do
      it "accepts the minimum value" do
        expect { deposit(BalanceService::MIN_VALUE.to_s) }.not_to raise_error
      end

      it "accepts the maximum value" do
        expect { deposit(BalanceService::MAX_VALUE.to_s) }.not_to raise_error
      end

      it "accepts a typical amount" do
        expect { deposit("5000") }.not_to raise_error
      end

      it "accepts an integer" do
        expect { deposit(5000) }.not_to raise_error
      end
    end

    context "with invalid format" do
      it "rejects decimal values" do
        expect { deposit("99.99") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects alphabetic strings" do
        expect { deposit("abc") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects empty string" do
        expect { deposit("") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects nil" do
        expect { deposit(nil) }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects negative strings" do
        expect { deposit("-100") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects strings with spaces" do
        expect { deposit("100 00") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects strings with leading whitespace" do
        expect { deposit(" 100") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects strings with special characters" do
        expect { deposit("1_000") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects comma-separated amounts" do
        expect { deposit("1,000") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects comma as decimal separator" do
        expect { deposit("100,50") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects alphanumeric mix" do
        expect { deposit("100abc") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects currency symbols" do
        expect { deposit("$100") }.to raise_error(BadRequestError, "Invalid amount format")
      end
    end

    context "with amounts below minimum" do
      it "rejects zero" do
        expect { deposit("0") }
          .to raise_error(BadRequestError, "Amount must be greater than or equal to #{BalanceService::MIN_VALUE}")
      end

      it "rejects 99 cents (just below $1.00)" do
        expect { deposit("99") }
          .to raise_error(BadRequestError, "Amount must be greater than or equal to #{BalanceService::MIN_VALUE}")
      end

      it "rejects 1 cent" do
        expect { deposit("1") }
          .to raise_error(BadRequestError, "Amount must be greater than or equal to #{BalanceService::MIN_VALUE}")
      end
    end

    context "with amounts above maximum" do
      it "rejects one cent above the maximum" do
        expect { deposit((BalanceService::MAX_VALUE + 1).to_s) }
          .to raise_error(BadRequestError, "Amount must be less than or equal to #{BalanceService::MAX_VALUE}")
      end

      it "rejects very large numbers" do
        expect { deposit("99999999999999999") }
          .to raise_error(BadRequestError, "Amount must be less than or equal to #{BalanceService::MAX_VALUE}")
      end
    end
  end
end
