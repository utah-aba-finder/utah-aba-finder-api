# Multi-Provider Access System

## Overview
This system allows users to access and manage multiple providers while maintaining a clear "active provider" context for operations.

## Key Features

### ✅ User-Provider Relationships
- **Legacy**: `User` belongs to one `Provider` (active provider)
- **New**: `User` has many `managed_providers` (all accessible providers)
- **Helper**: `all_managed_providers` combines both relationships

### ✅ Active Provider Context
- Users have one "active" provider at a time
- All provider-specific operations use the active provider
- Easy switching between providers

## API Endpoints

### 1. Assign Provider to User
```bash
POST /api/v1/providers/assign_provider_to_user
{
  "provider_id": 123,
  "user_id": 456
}
```

### 2. Get Accessible Providers
```bash
GET /api/v1/providers/accessible_providers
```
**Response:**
```json
{
  "providers": [
    {
      "id": 123,
      "name": "Provider One",
      "email": "provider1@example.com",
      "status": "approved",
      "is_current": true
    },
    {
      "id": 456,
      "name": "Provider Two", 
      "email": "provider2@example.com",
      "status": "approved",
      "is_current": false
    }
  ],
  "current_provider_id": 123,
  "total_count": 2
}
```

### 3. Set Active Provider
```bash
POST /api/v1/providers/set_active_provider
{
  "provider_id": 456
}
```
**Response:**
```json
{
  "success": true,
  "message": "Active provider updated successfully",
  "active_provider": {
    "id": 456,
    "name": "Provider Two",
    "email": "provider2@example.com"
  }
}
```

### 4. Provider Self Operations
All existing provider self endpoints now use the active provider:
- `GET /api/v1/provider_self` - Get active provider info
- `PATCH /api/v1/provider_self` - Update active provider
- `DELETE /api/v1/provider_self/remove_logo` - Remove active provider logo

## Implementation Details

### User Model Methods
```ruby
# Get all providers user can manage
def all_managed_providers
  providers = []
  providers << provider if provider.present?
  providers += managed_providers
  providers.uniq
end

# Set active provider
def set_active_provider(provider_id)
  target_provider = all_managed_providers.find { |p| p.id == provider_id.to_i }
  return false unless target_provider
  update!(provider_id: target_provider.id)
  true
end

# Get current active provider
def active_provider
  provider
end

# Check access to specific provider
def can_access_provider?(provider_id)
  all_managed_providers.any? { |p| p.id == provider_id.to_i }
end
```

### Security
- Users can only access providers they're assigned to
- All provider update operations check authorization
- Active provider context prevents confusion

### Usage Flow
1. **Assign providers** to user using `assign_provider_to_user`
2. **List accessible providers** using `accessible_providers`
3. **Set active provider** using `set_active_provider`
4. **Perform operations** - all provider operations use active provider context
5. **Switch providers** as needed using `set_active_provider`

## Testing
Run the multi-provider access tests:
```bash
rspec spec/requests/api/v1/provider_multi_access_spec.rb
```

## Migration Notes
- ✅ Backward compatible with existing single-provider users
- ✅ Existing provider self endpoints automatically use active provider
- ✅ Authorization checks prevent unauthorized access
- ✅ Clear error messages for access denied scenarios 