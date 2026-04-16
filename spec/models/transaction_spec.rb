require "rails_helper"

RSpec.describe Transaction do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:recipient).class_name("User").optional }
  end

  describe "validations" do
    it "rejects non-positive amount" do
      txn = build(:transaction, amount: 0)
      expect(txn).not_to be_valid
      expect(txn.errors[:amount]).to be_present
    end

    it "requires a kind" do
      txn = build(:transaction, kind: nil)
      expect(txn).not_to be_valid
    end

    context "idempotency_key" do
      it "allows unique idempotency_key" do
        txn = build(:transaction, :with_idempotency_key)
        expect(txn).to be_valid
      end

      it "rejects duplicate idempotency_key" do
        existing = create(:transaction, :with_idempotency_key)
        duplicate = build(:transaction, idempotency_key: existing.idempotency_key)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:idempotency_key]).to include("has already been taken")
      end
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
      expect(txn.amount).to eq(Money.from_amount(100))
    end

    it "creates a transfer transaction with recipient" do
      recipient = create(:user)
      txn = create(:transaction, :transfer, user: user, recipient: recipient, amount: 50)
      expect(txn).to be_transfer
      expect(txn.recipient).to eq(recipient)
    end

    it "persists idempotency_key" do
      key = SecureRandom.uuid
      txn = create(:transaction, user: user, idempotency_key: key)
      expect(txn.reload.idempotency_key).to eq(key)
    end
  end
end
