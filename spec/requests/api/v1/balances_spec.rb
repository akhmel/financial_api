require "rails_helper"

RSpec.describe "Api::V1::Balances" do
  let(:user) { create(:user, balance: 500) }

  describe "GET /api/v1/balance" do
    context "when authenticated" do
      it "returns the current balance" do
        get api_v1_balance_path, headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:user_id]).to eq(user.id)
        expect(json_response[:balance]).to eq(500.0)
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
    context "with valid amount" do
      it "increases the balance" do
        post deposit_api_v1_balance_path,
             params: { amount: 200 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(700.0)
      end

      it "creates a deposit transaction" do
        expect {
          post deposit_api_v1_balance_path,
               params: { amount: 200 }.to_json,
               headers: auth_headers(user)
        }.to change(Transaction, :count).by(1)

        expect(Transaction.last).to be_deposit
        expect(Transaction.last.amount).to eq(200)
      end
    end

    context "with decimal amount" do
      it "handles cents correctly" do
        post deposit_api_v1_balance_path,
             params: { amount: "99.99" }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(599.99)
      end
    end

    context "with zero amount" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: { amount: 0 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Amount must be positive")
      end
    end

    context "with negative amount" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: { amount: -50 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:bad_request)
        expect(json_response[:error]).to eq("Amount must be positive")
      end
    end

    context "without amount parameter" do
      it "returns bad request" do
        post deposit_api_v1_balance_path,
             params: {}.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post deposit_api_v1_balance_path,
             params: { amount: 100 }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/balance/withdraw" do
    context "with sufficient funds" do
      it "decreases the balance" do
        post withdraw_api_v1_balance_path,
             params: { amount: 200 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(300.0)
      end

      it "creates a withdraw transaction" do
        expect {
          post withdraw_api_v1_balance_path,
               params: { amount: 200 }.to_json,
               headers: auth_headers(user)
        }.to change(Transaction, :count).by(1)

        expect(Transaction.last).to be_withdraw
      end
    end

    context "withdrawing exact balance" do
      it "allows withdrawing the full balance" do
        post withdraw_api_v1_balance_path,
             params: { amount: 500 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:balance]).to eq(0.0)
      end
    end

    context "with insufficient funds" do
      it "returns unprocessable entity" do
        post withdraw_api_v1_balance_path,
             params: { amount: 999 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to eq("Insufficient funds")
      end

      it "does not change the balance" do
        post withdraw_api_v1_balance_path,
             params: { amount: 999 }.to_json,
             headers: auth_headers(user)

        expect(user.reload.balance).to eq(500)
      end
    end

    context "with zero amount" do
      it "returns bad request" do
        post withdraw_api_v1_balance_path,
             params: { amount: 0 }.to_json,
             headers: auth_headers(user)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post withdraw_api_v1_balance_path,
             params: { amount: 100 }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
