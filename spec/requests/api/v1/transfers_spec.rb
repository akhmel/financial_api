require "rails_helper"

RSpec.describe "Api::V1::Transfers" do
  let(:sender) { create(:user, balance: 1000) }
  let(:recipient) { create(:user, balance: 200) }

  describe "POST /api/v1/transfers" do
    context "with valid params and sufficient funds" do
      let(:params) { { recipient_id: recipient.id, amount: 30_000 } }

      it "returns created with transfer details" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:created)
        expect(json_response[:sender][:id]).to eq(sender.id)
        expect(json_response[:sender][:balance]).to eq(70_000)
        expect(json_response[:recipient][:id]).to eq(recipient.id)
        expect(json_response[:amount]).to eq(30_000)
      end

      it "debits the sender" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(sender.reload.balance_cents).to eq(70_000)
      end

      it "credits the recipient" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(recipient.reload.balance_cents).to eq(50_000)
      end

      it "creates a transfer transaction" do
        expect {
          post api_v1_transfers_path,
               params: params.to_json,
               headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)
        }.to change(Transaction, :count).by(1)

        txn = Transaction.last
        expect(txn).to be_transfer
        expect(txn.user).to eq(sender)
        expect(txn.recipient).to eq(recipient)
        expect(txn.amount_cents).to eq(30_000)
      end
    end

    context "with insufficient funds" do
      it "returns unprocessable entity" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 500_000 }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to eq("Insufficient funds")
      end

      it "does not change either balance" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 500_000 }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(sender.reload.balance_cents).to eq(100_000)
        expect(recipient.reload.balance_cents).to eq(20_000)
      end
    end

    context "when transferring to yourself" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: sender.id, amount: 10_000 }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Cannot transfer to yourself")
      end
    end

    context "when recipient does not exist" do
      it "returns not found" do
        post api_v1_transfers_path,
             params: { recipient_id: "00000000-0000-0000-0000-000000000000", amount: 10_000 }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with zero amount" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 0 }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Amount must be greater than or equal to #{MoneyValidator::MIN_VALUE}")
      end
    end

    context "with non-integer amount" do
      it "rejects decimal values" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: "0.50" }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Invalid amount format")
      end

      it "does not change either balance" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: "100.999" }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(sender.reload.balance_cents).to eq(100_000)
        expect(recipient.reload.balance_cents).to eq(20_000)
      end
    end

    context "with negative amount" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: -100 }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with too high amount" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: (MoneyValidator::MAX_VALUE + 1).to_s }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Amount must be less than or equal to #{MoneyValidator::MAX_VALUE}")
      end
    end

    context "without recipient_id" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { amount: 10_000 }.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 10_000 }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without idempotency key" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 10_000 }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Idempotency-Key header is required")
      end

      it "does not change either balance" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 10_000 }.to_json,
             headers: auth_headers(sender)

        expect(sender.reload.balance_cents).to eq(100_000)
        expect(recipient.reload.balance_cents).to eq(20_000)
      end
    end

    context "with idempotency key" do
      let(:key) { SecureRandom.uuid }
      let(:params) { { recipient_id: recipient.id, amount: 30_000 } }

      it "processes the first transfer normally" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:created)
        expect(sender.reload.balance_cents).to eq(70_000)
        expect(recipient.reload.balance_cents).to eq(50_000)
      end

      it "rejects a duplicate transfer" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:created)

        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:conflict)
        expect(json_response[:error]).to eq("Duplicate request")
      end

      it "does not double-debit sender on retry" do
        2.times do
          post api_v1_transfers_path,
               params: params.to_json,
               headers: auth_headers(sender).merge("Idempotency-Key" => key)
        end

        expect(sender.reload.balance_cents).to eq(70_000)
        expect(recipient.reload.balance_cents).to eq(50_000)
        expect(Transaction.where(idempotency_key: key).count).to eq(1)
      end
    end
  end
end
