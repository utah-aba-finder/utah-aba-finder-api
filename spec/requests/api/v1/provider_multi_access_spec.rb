require 'rails_helper'

RSpec.describe 'Multi-Provider Access', type: :request do
  let(:user) { create(:user) }
  let(:provider1) { create(:provider, name: 'Provider One', in_home_only: true) }
  let(:provider2) { create(:provider, name: 'Provider Two', in_home_only: true) }
  
  before do
    # Create provider assignments for both providers
    ProviderAssignment.create!(user: user, provider: provider1, assigned_by: 'test')
    ProviderAssignment.create!(user: user, provider: provider2, assigned_by: 'test')
    
    # Set provider1 as the active provider
    user.update!(active_provider_id: provider1.id)
  end

  describe 'GET /api/v1/providers/accessible_providers' do
    it 'returns all providers the user can access' do
      get '/api/v1/providers/accessible_providers', headers: { 'Authorization' => user.id.to_s }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json['providers']['data'].length).to eq(2)
      expect(json['current_provider_id']).to eq(provider1.id)
      expect(json['total_count']).to eq(2)
      
      provider_names = json['providers']['data'].map { |p| p['attributes']['name'] }
      expect(provider_names).to include('Provider One', 'Provider Two')
    end
  end

  describe 'POST /api/v1/providers/set_active_provider' do
    it 'changes the active provider' do
      post '/api/v1/providers/set_active_provider', 
           params: { provider_id: provider2.id },
           headers: { 'Authorization' => user.id.to_s }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json['active_provider_id']).to eq(provider2.id.to_s)
      
      # Verify the user's active provider was updated
      user.reload
      expect(user.active_provider).to eq(provider2)
    end

    it 'rejects setting a provider the user cannot access' do
      unauthorized_provider = create(:provider, name: 'Unauthorized Provider', in_home_only: true)
      
      post '/api/v1/providers/set_active_provider', 
           params: { provider_id: unauthorized_provider.id },
           headers: { 'Authorization' => user.id.to_s }
      
      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json['error']).to include('Forbidden')
    end
  end

  describe 'Provider self operations with active provider context' do
    it 'uses the active provider for self operations' do
      # Set provider2 as active
      user.update!(active_provider_id: provider2.id)
      
      get '/api/v1/provider_self', headers: { 'Authorization' => user.id.to_s }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json['data'][0]['id']).to eq(provider2.id)
      expect(json['data'][0]['attributes']['name']).to eq('Provider Two')
    end
  end

  describe 'Provider update authorization' do
    it 'allows updating providers the user has access to' do
      patch "/api/v1/providers/#{provider1.id}", 
            params: { name: 'Updated Provider One' },
            headers: { 'Authorization' => user.id.to_s }
      
      expect(response).to have_http_status(:ok)
    end

    it 'denies updating providers the user cannot access' do
      unauthorized_provider = create(:provider, name: 'Unauthorized Provider', in_home_only: true)
      
      patch "/api/v1/providers/#{unauthorized_provider.id}", 
            params: { name: 'Updated Unauthorized Provider' },
            headers: { 'Authorization' => user.id.to_s }
      
      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json['error']).to include('Access denied')
    end
  end
end 