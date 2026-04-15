require "rails_helper"

RSpec.describe User do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it "rejects negative balance" do
      user = build(:user, balance: -1)
      expect(user).not_to be_valid
      expect(user.errors[:balance]).to be_present
    end

    it "rejects invalid email format" do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "accepts valid email format" do
      user = build(:user, email: "valid@example.com")
      expect(user).to be_valid
    end
  end

  describe "default values" do
    it "has zero balance by default" do
      user = create(:user)
      expect(user.balance).to eq(Money.from_amount(0))
    end
  end

  describe "#sufficient_funds?" do
    let(:user) { build(:user, balance: 500) }

    it "returns true when balance covers the amount" do
      expect(user.sufficient_funds?(Money.from_amount(500))).to be true
    end

    it "returns true when balance exceeds the amount" do
      expect(user.sufficient_funds?(Money.from_amount(100))).to be true
    end

    it "returns false when balance is less than the amount" do
      expect(user.sufficient_funds?(Money.from_amount(501))).to be false
    end
  end
end
