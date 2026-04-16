require "rails_helper"

RSpec.describe "Api::V1::Sessions" do
  let(:password) { "correct-horse-battery-staple" }
  let(:user) { create(:user, password: password) }

  describe "POST /api/v1/session" do
    context "with valid credentials" do
      it "returns a JWT token" do
        post api_v1_session_path,
             params: { session: { email: user.email, password: password } }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:created)
        expect(json_response[:token]).to be_present
      end

      it "returns a token that decodes to the user id" do
        post api_v1_session_path,
             params: { session: { email: user.email, password: password } }.to_json,
             headers: json_headers

        payload = JwtService.decode(json_response[:token])
        expect(payload[:user_id]).to eq(user.id)
      end

      it "is case-insensitive for email" do
        post api_v1_session_path,
             params: { session: { email: user.email.upcase, password: password } }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:created)
        expect(json_response[:token]).to be_present
      end
    end

    context "with wrong password" do
      it "returns unauthorized" do
        post api_v1_session_path,
             params: { session: { email: user.email, password: "wrong-password-here" } }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Invalid email or password")
      end
    end

    context "with non-existent email" do
      it "returns unauthorized" do
        post api_v1_session_path,
             params: { session: { email: "nobody@example.com", password: password } }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Invalid email or password")
      end
    end

    context "with missing parameters" do
      it "returns unauthorized when email is missing" do
        post api_v1_session_path,
             params: { session: { password: password } }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Invalid email or password")
      end

      it "returns unauthorized when password is missing" do
        post api_v1_session_path,
             params: { session: { email: user.email } }.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Invalid email or password")
      end

      it "returns unauthorized when session key is missing" do
        post api_v1_session_path,
             params: {}.to_json,
             headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq("Invalid email or password")
      end
    end

    it "does not require authentication" do
      post api_v1_session_path,
           params: { session: { email: user.email, password: password } }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:created)
    end
  end
end
