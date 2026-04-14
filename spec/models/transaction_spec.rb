require "rails_helper"

RSpec.describe Transaction do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:recipient).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }

    it "requires a kind" do
      txn = build(:transaction, kind: nil)
      expect(txn).not_to be_valid
    end
  end

  describe "enum" do
    it { is_expected.to define_enum_for(:kind).with_values(deposit: 0, withdraw: 1, transfer: 2) }
  end

  describe "creation" do
    let(:user) { create(:user) }

    it "creates a deposit transaction" do
      txn = create(:transaction, user: user, kind: :deposit, amount: 100)
      expect(txn).to be_deposit
      expect(txn.amount).to eq(100)
    end

    it "creates a transfer transaction with recipient" do
      recipient = create(:user)
      txn = create(:transaction, :transfer, user: user, recipient: recipient, amount: 50)
      expect(txn).to be_transfer
      expect(txn.recipient).to eq(recipient)
    end
  end
end
