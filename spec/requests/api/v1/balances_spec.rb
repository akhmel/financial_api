require "rails_helper"

RSpec.describe "Api::V1::Balances" do
  let(:user) { create(:user, balance: 500) }

  describe "GET /api/v1/balance" do
    context "when authenticated" do
      it "returns the current balance in cents" do
        get api_v1_balance_path, headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:user_id]).to eq(user.id)
        expect(json_response[:balance]).to eq(50_000)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get api_v1_balance_path

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/balance/deposit" do
    context "with too high amount" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: { amount: (MoneyValidator::MAX_VALUE + 1).to_s }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Amount must be less than or equal to #{MoneyValidator::MAX_VALUE}")
      end
    end

    context "with valid amount" do
      it "increases the balance" do
        post deposit_api_v1_balance_path,
             params: { amount: 20_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(70_000)
      end

      it "creates a deposit transaction" do
        expect {
          post deposit_api_v1_balance_path,
               params: { amount: 20_000 }.to_json,
               headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)
        }.to change(Transaction, :count).by(1)

        expect(Transaction.last).to be_deposit
        expect(Transaction.last.amount_cents).to eq(20_000)
      end
    end

    context "with non-integer amount" do
      it "rejects decimal values" do
        post deposit_api_v1_balance_path,
             params: { amount: "99.99" }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Invalid amount format")
      end

      it "does not change the balance" do
        post deposit_api_v1_balance_path,
             params: { amount: "100.50" }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(user.reload.balance_cents).to eq(50_000)
      end
    end

    context "with zero amount" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: { amount: 0 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Amount must be greater than or equal to #{MoneyValidator::MIN_VALUE}")
      end
    end

    context "with negative amount" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: { amount: -50 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Invalid amount format")
      end
    end

    context "without amount parameter" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: {}.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with idempotency key" do
      let(:key) { SecureRandom.uuid }

      it "processes the first request normally" do
        post deposit_api_v1_balance_path,
             params: { amount: 20_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(70_000)
      end

      it "rejects a duplicate request with the same key" do
        post deposit_api_v1_balance_path,
             params: { amount: 20_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:ok)

        post deposit_api_v1_balance_path,
             params: { amount: 20_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:conflict)
        expect(json_response[:error]).to eq("Duplicate request")
      end

      it "does not apply the balance twice" do
        2.times do
          post deposit_api_v1_balance_path,
               params: { amount: 20_000 }.to_json,
               headers: auth_headers(user).merge("Idempotency-Key" => key)
        end

        expect(user.reload.balance_cents).to eq(70_000)
      end
    end

    context "without idempotency key" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: { amount: 10_000 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Idempotency-Key header is required")
      end

      it "does not change the balance" do
        post deposit_api_v1_balance_path,
             params: { amount: 10_000 }.to_json,
             headers: auth_headers(user)

        expect(user.reload.balance_cents).to eq(50_000)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post deposit_api_v1_balance_path,
             params: { amount: 10_000 }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/balance/withdraw" do
    context "with sufficient funds" do
      it "decreases the balance" do
        post withdraw_api_v1_balance_path,
             params: { amount: 20_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(30_000)
      end

      it "creates a withdraw transaction" do
        expect {
          post withdraw_api_v1_balance_path,
               params: { amount: 20_000 }.to_json,
               headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)
        }.to change(Transaction, :count).by(1)

        expect(Transaction.last).to be_withdraw
      end
    end

    context "withdrawing exact balance" do
      it "allows withdrawing the full balance" do
        post withdraw_api_v1_balance_path,
             params: { amount: 50_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(0)
      end
    end

    context "with insufficient funds" do
      it "returns unprocessable entity" do
        post withdraw_api_v1_balance_path,
             params: { amount: 99_900 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to eq("Insufficient funds")
      end

      it "does not change the balance" do
        post withdraw_api_v1_balance_path,
             params: { amount: 99_900 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(user.reload.balance_cents).to eq(50_000)
      end
    end

    context "with too high amount" do
      it "returns bad request" do
        post withdraw_api_v1_balance_path,
             params: { amount: (MoneyValidator::MAX_VALUE + 1).to_s }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with idempotency key" do
      let(:key) { SecureRandom.uuid }

      it "rejects a duplicate withdrawal" do
        post withdraw_api_v1_balance_path,
             params: { amount: 10_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(40_000)

        post withdraw_api_v1_balance_path,
             params: { amount: 10_000 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => key)

        expect(response).to have_http_status(:conflict)
        expect(user.reload.balance_cents).to eq(40_000)
      end
    end

    context "without idempotency key" do
      it "returns bad request" do
        post withdraw_api_v1_balance_path,
             params: { amount: 10_000 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Idempotency-Key header is required")
      end
    end

    context "with non-integer amount" do
      it "rejects decimal values" do
        post withdraw_api_v1_balance_path,
             params: { amount: "0.50" }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Invalid amount format")
      end

      it "does not change the balance" do
        post withdraw_api_v1_balance_path,
             params: { amount: "100.001" }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(user.reload.balance_cents).to eq(50_000)
      end
    end

    context "with zero amount" do
      it "returns bad request" do
        post withdraw_api_v1_balance_path,
             params: { amount: 0 }.to_json,
             headers: auth_headers(user).merge("Idempotency-Key" => SecureRandom.uuid)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post withdraw_api_v1_balance_path,
             params: { amount: 10_000 }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
