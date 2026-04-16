require "rails_helper"

RSpec.describe MoneyValidator do
  describe ".validate!" do
    context "with valid amounts" do
      it "accepts the minimum value" do
        expect(described_class.validate!(100)).to eq(100)
      end

      it "accepts the maximum value" do
        expect(described_class.validate!(MoneyValidator::MAX_VALUE)).to eq(MoneyValidator::MAX_VALUE)
      end

      it "accepts a typical amount" do
        expect(described_class.validate!(5000)).to eq(5000)
      end

      it "accepts a string integer" do
        expect(described_class.validate!("5000")).to eq(5000)
      end
    end

    context "with invalid format" do
      it "rejects decimal values" do
        expect { described_class.validate!("99.99") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects alphabetic strings" do
        expect { described_class.validate!("abc") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects empty string" do
        expect { described_class.validate!("") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects nil" do
        expect { described_class.validate!(nil) }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects negative strings" do
        expect { described_class.validate!("-100") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects strings with spaces" do
        expect { described_class.validate!("100 00") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects strings with leading whitespace" do
        expect { described_class.validate!(" 100") }.to raise_error(BadRequestError, "Invalid amount format")
      end

      it "rejects strings with special characters" do
        expect { described_class.validate!("1_000") }.to raise_error(BadRequestError, "Invalid amount format")
      end
    end

    context "with amounts below minimum" do
      it "rejects zero" do
        expect { described_class.validate!("0") }
          .to raise_error(BadRequestError, "Amount must be greater than or equal to #{MoneyValidator::MIN_VALUE}")
      end

      it "rejects 99 cents (just below $1.00)" do
        expect { described_class.validate!("99") }
          .to raise_error(BadRequestError, "Amount must be greater than or equal to #{MoneyValidator::MIN_VALUE}")
      end

      it "rejects 1 cent" do
        expect { described_class.validate!("1") }
          .to raise_error(BadRequestError, "Amount must be greater than or equal to #{MoneyValidator::MIN_VALUE}")
      end
    end

    context "with amounts above maximum" do
      it "rejects one cent above the maximum" do
        expect { described_class.validate!(MoneyValidator::MAX_VALUE + 1) }
          .to raise_error(BadRequestError, "Amount must be less than or equal to #{MoneyValidator::MAX_VALUE}")
      end

      it "rejects very large numbers" do
        expect { described_class.validate!("99999999999999999") }
          .to raise_error(BadRequestError, "Amount must be less than or equal to #{MoneyValidator::MAX_VALUE}")
      end
    end
  end

  describe ".parse!" do
    it "returns a Money object for a valid amount" do
      result = described_class.parse!(5000)
      expect(result).to be_a(Money)
      expect(result.cents).to eq(5000)
    end

    it "raises on invalid input" do
      expect { described_class.parse!("abc") }.to raise_error(BadRequestError)
    end
  end
end
