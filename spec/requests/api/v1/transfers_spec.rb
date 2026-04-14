require "rails_helper"

RSpec.describe "Api::V1::Transfers" do
  let(:sender) { create(:user, balance: 1000) }
  let(:recipient) { create(:user, balance: 200) }

  describe "POST /api/v1/transfers" do
    context "with valid params and sufficient funds" do
      let(:params) { { recipient_id: recipient.id, amount: 300 } }

      it "returns created with transfer details" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:created)
        expect(json_response[:sender][:id]).to eq(sender.id)
        expect(json_response[:sender][:balance]).to eq(700.0)
        expect(json_response[:recipient][:id]).to eq(recipient.id)
        expect(json_response[:amount]).to eq(300.0)
      end

      it "debits the sender" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender)

        expect(sender.reload.balance).to eq(700)
      end

      it "credits the recipient" do
        post api_v1_transfers_path,
             params: params.to_json,
             headers: auth_headers(sender)

        expect(recipient.reload.balance).to eq(500)
      end

      it "creates a transfer transaction" do
        expect {
          post api_v1_transfers_path,
               params: params.to_json,
               headers: auth_headers(sender)
        }.to change(Transaction, :count).by(1)

        txn = Transaction.last
        expect(txn).to be_transfer
        expect(txn.user).to eq(sender)
        expect(txn.recipient).to eq(recipient)
        expect(txn.amount).to eq(300)
      end
    end

    context "with insufficient funds" do
      it "returns unprocessable entity" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 5000 }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to eq("Insufficient funds")
      end

      it "does not change either balance" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 5000 }.to_json,
             headers: auth_headers(sender)

        expect(sender.reload.balance).to eq(1000)
        expect(recipient.reload.balance).to eq(200)
      end
    end

    context "when transferring to yourself" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: sender.id, amount: 100 }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Cannot transfer to yourself")
      end
    end

    context "when recipient does not exist" do
      it "returns not found" do
        post api_v1_transfers_path,
             params: { recipient_id: "00000000-0000-0000-0000-000000000000", amount: 100 }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with zero amount" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 0 }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Amount must be positive")
      end
    end

    context "with negative amount" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: -100 }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without recipient_id" do
      it "returns bad request" do
        post api_v1_transfers_path,
             params: { amount: 100 }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: 100 }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with decimal amount" do
      it "handles cents correctly" do
        post api_v1_transfers_path,
             params: { recipient_id: recipient.id, amount: "150.75" }.to_json,
             headers: auth_headers(sender)

        expect(response).to have_http_status(:created)
        expect(sender.reload.balance).to eq(849.25)
        expect(recipient.reload.balance).to eq(350.75)
      end
    end
  end
end
