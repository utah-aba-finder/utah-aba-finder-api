# Provider Access & Data Update Setup Guide

This guide explains exactly what needs to be set up for providers to successfully update or add their data, preventing authentication and authorization errors.

## Table of Contents
1. [User-Provider Relationships](#user-provider-relationships)
2. [Authentication Requirements](#authentication-requirements)
3. [Setting Up Provider Access](#setting-up-provider-access)
4. [Frontend Requirements](#frontend-requirements)
5. [Endpoints & Access Rules](#endpoints--access-rules)
6. [Troubleshooting Common Issues](#troubleshooting-common-issues)
7. [Quick Reference Checklist](#quick-reference-checklist)

---

## User-Provider Relationships

The system supports three ways for a user to access a provider:

### 1. Primary Owner (Legacy + New)
- **Database Field**: `provider.user_id` = user's ID
- **Legacy Field**: `user.provider_id` = provider's ID
- **How to Set**: Set `provider.user_id` OR `user.provider_id` (both work)
- **Access**: Full access to update provider data

### 2. Provider Assignment (New Multi-Provider System)
- **Database Table**: `provider_assignments`
- **Fields**: `user_id`, `provider_id`, `assigned_by`
- **How to Set**: Create a `ProviderAssignment` record
- **Access**: Full access to update provider data

### 3. Active Provider Context
- **Database Field**: `user.active_provider_id` = provider's ID
- **Purpose**: Determines which provider is "active" for operations
- **Required For**: `/api/v1/provider_self` endpoints
- **Note**: This is separate from ownership/assignment

### Access Check Logic
A user can access a provider if ANY of these are true:
- `provider.user_id == user.id` (primary owner via provider)
- `user.provider_id == provider.id` (primary owner via user - legacy)
- A `ProviderAssignment` exists linking user to provider
- `user.role == 'super_admin'` (admins can access any provider)

**Method**: `user.can_access_provider?(provider_id)` returns `true` if any condition is met.

---

## Authentication Requirements

### Authentication Methods

The API supports three authentication methods:

#### 1. Bearer Token (User ID or Email) ✅ RECOMMENDED
```http
Authorization: Bearer 142
```
or
```http
Authorization: Bearer cgoforth@abskids.com
```

**How it works:**
- Backend looks up user by ID (if numeric) or email (if contains `@`)
- Case-insensitive email matching
- Sets `@current_user` for access checks

#### 2. Provider Self-Authentication (Provider ID) ⚠️ WORKS BUT NOT RECOMMENDED
```http
Authorization: 8
```

**How it works:**
- Backend finds provider by ID
- Only works if `provider.id == params[:id]`
- Sets `@current_provider` instead of `@current_user`
- Limited to specific endpoints that handle `@current_provider`

**⚠️ Important**: This method has limitations and should only be used when user ID is unavailable.

#### 3. API Key (Client Authentication)
```http
Authorization: your-api-key-here
```

**How it works:**
- Used for admin/client integrations
- Sets `@current_client`
- Full access to all providers

---

## Setting Up Provider Access

### Method 1: Assign Provider to User (Recommended for Admins)

**Endpoint**: `POST /api/v1/providers/assign_provider_to_user`

**Requirements**:
- Authenticated as super_admin
- Both user and provider must exist

**Request**:
```json
{
  "user_email": "cgoforth@abskids.com",
  "provider_id": 8
}
```

**What it does**:
1. Creates a `ProviderAssignment` record
2. Updates `user.provider_id` (legacy field) if not already set
3. Returns success confirmation

**Response**:
```json
{
  "success": true,
  "message": "User cgoforth@abskids.com successfully assigned to provider ABS Kids",
  "user": {
    "id": 142,
    "email": "cgoforth@abskids.com",
    "role": "provider_admin",
    "provider_id": 8
  },
  "provider": {
    "id": 8,
    "name": "ABS Kids",
    "email": "info@abskids.com"
  }
}
```

### Method 2: Link User to Provider (Alternative)

**Endpoint**: `POST /api/v1/users/:id/link_to_provider`

**Requirements**:
- Authenticated user
- Provider must exist

**Request**:
```json
{
  "provider_id": 8
}
```

**What it does**:
1. Updates `user.provider_id` (legacy)
2. Creates `ProviderAssignment` if doesn't exist
3. Sets `user.active_provider_id` if not set

### Method 3: Claim Account (For Providers Claiming Their Account)

**Endpoint**: `POST /api/v1/providers/claim_account`

**Requirements**:
- Provider must exist and be approved
- No authentication required (public endpoint)

**Request**:
```json
{
  "claimer_email": "cgoforth@abskids.com",
  "provider_id": 8
}
```

**What it does**:
1. Finds or creates user with `claimer_email`
2. Links user to provider (sets `provider.user_id` if none exists, or creates `ProviderAssignment`)
3. Sets `user.active_provider_id`
4. Sends welcome email if new user

---

## Frontend Requirements

### ✅ Required: Send User ID in Authorization Header

**Correct Format**:
```javascript
const userId = user.id; // e.g., 142
const headers = {
  'Authorization': `Bearer ${userId}`,
  // OR without Bearer prefix (also works):
  'Authorization': userId.toString(),
  'Content-Type': 'application/json'
};
```

**Also Acceptable** (Email):
```javascript
const userEmail = user.email; // e.g., "cgoforth@abskids.com"
const headers = {
  'Authorization': `Bearer ${userEmail}`,
  'Content-Type': 'application/json'
};
```

### ❌ Avoid: Sending Provider ID

**Incorrect Format** (works but not recommended):
```javascript
const providerId = provider.id; // e.g., 8
const headers = {
  'Authorization': providerId.toString(), // ⚠️ Works but limited
  'Content-Type': 'application/json'
};
```

**Why avoid?**
- Limited to specific endpoints
- Doesn't work for all operations
- Less secure (provider ID is less private than user ID)

### Required Headers for All Requests

```javascript
{
  'Authorization': `Bearer ${userId}`, // User ID or email
  'Content-Type': 'application/json',  // For JSON requests
  'Accept': 'application/json'
}
```

For multipart/form-data (logo uploads):
```javascript
{
  'Authorization': `Bearer ${userId}`,
  // Don't set Content-Type - browser will set it with boundary
}
```

---

## Endpoints & Access Rules

### Provider Data Update Endpoints

#### 1. Update Provider (Basic Info, Ages, Services, etc.)
- **Endpoint**: `PATCH /api/v1/providers/:id`
- **Authentication**: `authenticate_provider_or_client`
- **Access Check**: 
  - `@current_user.can_access_provider?(provider.id)` OR
  - `@current_provider.id == provider.id` OR
  - `@current_client` (API key)
- **What it updates**: Basic provider fields, locations, insurance, counties, practice types

#### 2. Provider Self (Simplified Endpoint)
- **Endpoint**: `PATCH /api/v1/provider_self`
- **Authentication**: `authenticate_user!` (requires user authentication)
- **Access Check**: Uses `@current_user.active_provider` OR `@current_user.provider`
- **What it updates**: Same as above, but automatically uses active provider
- **Note**: Requires `user.active_provider_id` to be set OR `user.provider_id` to be set

#### 3. Location Management

**Get Locations**:
- **Endpoint**: `GET /api/v1/providers/:id/locations`
- **Authentication**: `authenticate_provider_or_client`
- **Access Check**: Same as Update Provider

**Add Location**:
- **Endpoint**: `POST /api/v1/providers/:id/locations`
- **Authentication**: `authenticate_provider_or_client`
- **Access Check**: Same as Update Provider

**Update Location**:
- **Endpoint**: `PATCH /api/v1/providers/:id/locations/:location_id`
- **Authentication**: `authenticate_provider_or_client`
- **Access Check**: Same as Update Provider

**Remove Location**:
- **Endpoint**: `DELETE /api/v1/providers/:id/locations/:location_id`
- **Authentication**: `authenticate_provider_or_client`
- **Access Check**: Same as Update Provider

---

## Troubleshooting Common Issues

### Issue 1: 401 Unauthorized

**Symptoms**: 
- Error: "Unauthorized" or "No authorization token provided"
- Status: 401

**Causes & Solutions**:

1. **Missing Authorization Header**
   - ✅ **Fix**: Include `Authorization` header with user ID or email

2. **Invalid Token Format**
   - ✅ **Fix**: Use `Bearer ${userId}` or just `${userId}` (user ID, not provider ID)

3. **User Not Found**
   - ✅ **Fix**: Verify user exists in database with that ID/email
   - ✅ **Check**: User email is case-insensitive but should match exactly

4. **Token is Provider ID**
   - ⚠️ **Partial Fix**: This works for some endpoints but not all
   - ✅ **Better Fix**: Use user ID instead

### Issue 2: 403 Forbidden

**Symptoms**:
- Error: "Access denied" or "You do not have permission to access this provider"
- Status: 403

**Causes & Solutions**:

1. **User Not Linked to Provider**
   - ✅ **Fix**: Assign user to provider using one of these methods:
     - `POST /api/v1/providers/assign_provider_to_user` (admin only)
     - `POST /api/v1/users/:id/link_to_provider`
     - `POST /api/v1/providers/claim_account`

2. **Provider Assignment Missing**
   - ✅ **Fix**: Ensure `ProviderAssignment` exists OR `provider.user_id == user.id` OR `user.provider_id == provider.id`
   - ✅ **Verify**: Run `user.can_access_provider?(provider_id)` should return `true`

3. **Using Provider ID Instead of User ID**
   - ⚠️ **Partial Fix**: Some endpoints support this, but not all
   - ✅ **Better Fix**: Use user ID in Authorization header

### Issue 3: 500 Internal Server Error

**Symptoms**:
- Error: "InvalidSignature" or "unexpected error"
- Status: 500

**Causes & Solutions**:

1. **Signed/Encrypted Parameters in Request**
   - ✅ **Fix**: Don't send these fields in update requests:
     - `password`
     - `username`
     - `id`
     - `states` (derived from counties, don't send directly)
     - `category`, `category_name`
     - `provider_attributes`, `category_fields`
     - `updated_last`

2. **Invalid Parameter Structure**
   - ✅ **Fix**: Follow the expected structure:
   ```json
   {
     "data": {
       "attributes": {
         "name": "Provider Name",
         "min_age": 2,
         "max_age": 18
       }
     }
   }
   ```

### Issue 4: Data Saves But Disappears

**Symptoms**:
- Update appears successful (200 OK)
- Data doesn't persist or disappears

**Causes & Solutions**:

1. **Case-Sensitivity in Provider Attributes**
   - ✅ **Fix**: Backend now handles case-insensitive field matching
   - ✅ **Verify**: Field names should match category field names (case-insensitive)

2. **Wrong Provider Context**
   - ✅ **Fix**: Ensure `user.active_provider_id` is set correctly
   - ✅ **Check**: Verify which provider is being updated matches the active provider

---

## Quick Reference Checklist

### For Each Provider That Needs Update Access:

- [ ] **User exists** in database with correct email
- [ ] **Provider exists** and is approved (`status = 'approved'`)
- [ ] **User is linked to provider** via ONE of:
  - [ ] `provider.user_id == user.id` (primary owner)
  - [ ] `user.provider_id == provider.id` (legacy link)
  - [ ] `ProviderAssignment` exists (new multi-provider system)
- [ ] **User's active_provider_id is set** (for `/provider_self` endpoints)
- [ ] **Frontend sends user ID** (not provider ID) in Authorization header
- [ ] **Authorization header format**: `Bearer ${userId}` or `${userId}`

### Verification Queries (Rails Console)

```ruby
# Check if user can access provider
user = User.find_by(email: "cgoforth@abskids.com")
provider = Provider.find(8)
user.can_access_provider?(provider.id) # Should return true

# Check all relationships
user.provider_id # Should be provider.id if legacy link exists
provider.user_id # Should be user.id if primary owner
ProviderAssignment.exists?(user: user, provider: provider) # Should be true if assigned
user.active_provider_id # Should be provider.id if set

# Check all providers user can access
user.all_managed_providers.pluck(:id, :name)
```

### Common Setup Commands

```ruby
# Assign provider to user (creates assignment + sets legacy field)
user = User.find_by(email: "cgoforth@abskids.com")
provider = Provider.find(8)

# Method 1: Create assignment (recommended)
ProviderAssignment.create!(
  user: user,
  provider: provider,
  assigned_by: "admin@example.com"
)

# Method 2: Set legacy fields
user.update!(provider_id: provider.id)
provider.update!(user_id: user.id)

# Method 3: Set active provider
user.update!(active_provider_id: provider.id)
```

---

## Summary: What to Set

### Minimum Required Setup (Choose One Path):

**Path A: Primary Owner (Simplest)**
```
1. Set provider.user_id = user.id
   OR
2. Set user.provider_id = provider.id
```

**Path B: Provider Assignment (Multi-Provider System)**
```
1. Create ProviderAssignment(user: user, provider: provider)
2. Optionally set user.provider_id for backward compatibility
```

**Path C: Both (Most Robust)**
```
1. Set provider.user_id = user.id
2. Create ProviderAssignment(user: user, provider: provider)
3. Set user.active_provider_id = provider.id
```

### Frontend Must Send:
- ✅ User ID (or email) in `Authorization` header
- ✅ Format: `Bearer ${userId}` (recommended) or `${userId}`
- ✅ NOT provider ID (though it works for some endpoints)

### Result:
✅ User can update provider data via:
- `PATCH /api/v1/providers/:id`
- `PATCH /api/v1/provider_self` (if active_provider_id is set)
- All location endpoints
- All provider-related endpoints

---

**Last Updated**: December 2024
**Version**: 1.0

