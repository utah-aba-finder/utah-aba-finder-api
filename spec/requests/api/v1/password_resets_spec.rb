require 'rails_helper'

RSpec.describe "Api::V1::PasswordResets", type: :request do
  let!(:user) do
    create(:user, email: 'provider@example.com', password: 'OldPassword1!', password_confirmation: 'OldPassword1!')
  end

  before { ActionMailer::Base.deliveries.clear }

  describe "POST /api/v1/password_resets" do
    it "sends reset instructions for a known email" do
      post "/api/v1/password_resets", params: { email: user.email }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to include("sent")
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "accepts nested password_reset.email" do
      post "/api/v1/password_resets", params: { password_reset: { email: user.email } }

      expect(response).to have_http_status(:ok)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "matches email case-insensitively" do
      post "/api/v1/password_resets", params: { email: user.email.upcase }

      expect(response).to have_http_status(:ok)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "returns a generic message for unknown emails" do
      post "/api/v1/password_resets", params: { email: "nobody@example.com" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to include("If the email exists")
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "requires an email" do
      post "/api/v1/password_resets", params: {}

      expect(response).to have_http_status(422)
    end
  end

  describe "GET /api/v1/password_resets/validate_token" do
    it "returns valid for a fresh token" do
      token = user.send(:set_reset_password_token)

      get "/api/v1/password_resets/validate_token", params: { token: token }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["valid"]).to eq(true)
    end

    it "returns invalid for a bad token" do
      get "/api/v1/password_resets/validate_token", params: { token: "not-a-real-token" }

      expect(response).to have_http_status(422)
      expect(JSON.parse(response.body)["valid"]).to eq(false)
    end
  end

  describe "PATCH /api/v1/password_resets" do
    it "updates the password when token and confirmation match" do
      token = user.send(:set_reset_password_token)

      patch "/api/v1/password_resets", params: {
        reset_password_token: token,
        password: "NewPassword1!",
        password_confirmation: "NewPassword1!"
      }

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.valid_password?("NewPassword1!")).to be true
    end

    it "accepts PATCH /api/v1/password_resets/update alias" do
      token = user.send(:set_reset_password_token)

      patch "/api/v1/password_resets/update", params: {
        reset_password_token: token,
        password: "AnotherPass1!",
        password_confirmation: "AnotherPass1!"
      }

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.valid_password?("AnotherPass1!")).to be true
    end

    it "rejects mismatched confirmation" do
      token = user.send(:set_reset_password_token)

      patch "/api/v1/password_resets", params: {
        reset_password_token: token,
        password: "NewPassword1!",
        password_confirmation: "Different1!"
      }

      expect(response).to have_http_status(422)
    end
  end
end
