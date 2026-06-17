require 'rails_helper'

RSpec.describe "Api::V1::Users manual linking", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:provider1) { create(:provider, name: 'Provider One', in_home_only: true) }
  let(:provider2) { create(:provider, name: 'Provider Two', in_home_only: true) }
  let!(:target_user) do
    create(:user, email: 'multi@example.com', provider_id: provider1.id, active_provider_id: provider1.id)
  end

  before do
    ProviderAssignment.create!(user: target_user, provider: provider1, assigned_by: 'setup')
  end

  describe "POST /api/v1/users/manual_link" do
    it "links a user to an additional provider without replacing the primary provider" do
      post "/api/v1/users/manual_link",
           params: { user_email: target_user.email, provider_id: provider2.id },
           headers: { 'Authorization' => "Bearer #{super_admin.id}" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to eq(true)

      target_user.reload
      expect(target_user.provider_id).to eq(provider1.id)
      expect(target_user.all_managed_providers.map(&:id)).to contain_exactly(provider1.id, provider2.id)
    end

    it "matches email case-insensitively" do
      post "/api/v1/users/manual_link",
           params: { user_email: target_user.email.upcase, provider_id: provider2.id },
           headers: { 'Authorization' => "Bearer #{super_admin.id}" }

      expect(response).to have_http_status(:ok)
      expect(ProviderAssignment.exists?(user: target_user, provider: provider2)).to be true
    end

    it "returns success when the user is already linked" do
      ProviderAssignment.create!(user: target_user, provider: provider2, assigned_by: 'setup')

      post "/api/v1/users/manual_link",
           params: { user_email: target_user.email, provider_id: provider2.id },
           headers: { 'Authorization' => "Bearer #{super_admin.id}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to include("already has access")
    end
  end
end
