require "rails_helper"

RSpec.describe "Api::V1::Users" do
  describe "POST /api/v1/users" do
    let(:valid_params) { { user: { email: "new@example.com", password: "correct-horse-battery-staple", password_confirmation: "correct-horse-battery-staple" } } }

    context "with valid params" do
      it "creates a user and returns a JWT token" do
        post api_v1_users_path, params: valid_params.to_json, headers: json_headers

        expect(response).to have_http_status(:created)
        expect(json_response[:user][:email]).to eq("new@example.com")
        expect(json_response[:user][:balance]).to eq(0.0)
        expect(json_response[:token]).to be_present
      end

      it "increments the user count" do
        expect {
          post api_v1_users_path, params: valid_params.to_json, headers: json_headers
        }.to change(User, :count).by(1)
      end
    end

    context "with invalid email" do
      it "returns unprocessable entity" do
        post api_v1_users_path, params: { user: { email: "bad", password: "correct-horse-battery-staple" } }.to_json, headers: json_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to include("Email is invalid")
      end
    end

    context "with duplicate email" do
      before { create(:user, email: "taken@example.com") }

      it "returns unprocessable entity" do
        post api_v1_users_path, params: { user: { email: "taken@example.com", password: "correct-horse-battery-staple" } }.to_json, headers: json_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to include("Email has already been taken")
      end
    end

    context "with missing email" do
      it "returns unprocessable entity" do
        post api_v1_users_path, params: { user: { email: "", password: "correct-horse-battery-staple" } }.to_json, headers: json_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response[:error]).to include("Email")
      end
    end

    it "does not require authentication" do
      post api_v1_users_path, params: valid_params.to_json, headers: json_headers

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/v1/users/:id" do
    let(:user) { create(:user, :with_balance) }

    context "when authenticated" do
      it "returns the user with balance" do
        get api_v1_user_path(user), headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response[:user][:id]).to eq(user.id)
        expect(json_response[:user][:email]).to eq(user.email)
        expect(json_response[:user][:balance]).to eq(1000.0)
      end
    end

    context "when requesting another user" do
      it "returns unauthorized" do
        other = create(:user)
        get api_v1_user_path(other), headers: auth_headers(user)

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Forbidden")
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get api_v1_user_path(user)

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Missing token")
      end
    end

    context "with invalid token" do
      it "returns unauthorized" do
        get api_v1_user_path(user), headers: { "Authorization" => "Bearer invalid.token.here" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
