require "rails_helper"

RSpec.describe "Api::V1::Users" do
  describe "POST /api/v1/users" do
    let(:valid_params) { { user: { email: "new@example.com", password: "correct-horse-battery-staple", password_confirmation: "correct-horse-battery-staple" } } }

    context "with valid params" do
      it "creates a user and returns user details" do
        post api_v1_users_path, params: valid_params.to_json, headers: json_headers

        expect(response).to have_http_status(:created)
        expect(json_response[:email]).to eq("new@example.com")
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
end
