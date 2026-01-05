# PATCH /api/v1/provider_self - Provider Self-Update Endpoint

## Route
```
PATCH /api/v1/provider_self
```

## Authentication
- **Required**: Bearer token in `Authorization` header
- **Format**: `Authorization: Bearer <user_id_or_email>`
- **Controller**: `Api::V1::ProviderSelfController`
- **Before Actions**:
  - `authenticate_user!` - Validates user authentication
  - `set_provider` - Sets `@provider` to the user's active provider or primary provider

## Request Format

### Content-Type Options

#### 1. JSON (for regular updates)
```
Content-Type: application/json
```

#### 2. Multipart Form Data (for logo uploads)
```
Content-Type: multipart/form-data
```

## Request Body Structure

### JSON Format (Standard Updates)

```json
{
  "data": [
    {
      "attributes": {
        // Basic provider fields
        "name": "Provider Name",
        "website": "https://example.com",
        "email": "provider@example.com",
        "phone": "(555) 123-4567",
        "cost": "Contact for pricing",
        "min_age": 2,
        "max_age": 18,
        "waitlist": "1-2 weeks",
        "telehealth_services": true,
        "spanish_speakers": true,
        "at_home_services": true,
        "in_clinic_services": true,
        "in_home_only": false,
        "service_delivery": {
          "in_home": true,
          "in_clinic": true,
          "telehealth": true
        },
        
        // Locations (CRITICAL: Must include ALL locations when updating)
        "locations": [
          {
            "id": 123,  // Include ID for existing locations
            "name": "Main Office",
            "address_1": "123 Main St",
            "address_2": "Suite 100",
            "city": "Salt Lake City",
            "state": "UT",
            "zip": "84101",
            "phone": "(555) 123-4567",
            "email": "location@example.com",
            "in_home_waitlist": "Contact for availability",
            "in_clinic_waitlist": "No waitlist",
            "primary": true,  // Optional: mark as primary
            "services": [
              { "id": 1, "name": "ABA Therapy" }
            ]
          },
          {
            // New location (no ID)
            "name": "Second Location",
            "phone": "(555) 987-6543",
            "primary": false
          }
        ],
        
        // Primary location ID (alternative to primary: true flag)
        "primary_location_id": 123,
        
        // Insurance
        "insurance": [
          { "id": 1, "name": "Aetna" },
          { "id": 2, "name": "Blue Cross" }
        ],
        
        // Counties served
        "counties_served": [
          { "county_id": 1 },
          { "county_id": 2 }
        ],
        
        // Practice types
        "provider_type": [
          { "id": 1, "name": "ABA Therapy" },
          { "id": 2, "name": "Speech Therapy" }
        ],
        
        // Category-specific attributes (for educational programs, etc.)
        "provider_attributes": {
          "Age Groups": ["3-5 (PreK)", "5-7 (Kindergarten-2nd Grade)"],
          "Credentials/Qualifications": ["Licensed Teacher", "BCBA/ABA Specialist"],
          "Delivery Format": ["Online Only", "In-Person"]
        }
      }
    }
  ]
}
```

### Multipart Format (Logo Uploads)

```
Content-Type: multipart/form-data

name: Provider Name
website: https://example.com
email: provider@example.com
phone: (555) 123-4567
logo: [file]
... (other fields)
```

## Permitted Parameters

### Basic Provider Fields
- `name`
- `website`
- `email`
- `phone` ⚠️ **Note**: Provider-level phone field exists but frontend typically uses location-level phone (see Location Fields below)
- `cost`
- `min_age`
- `max_age`
- `waitlist`
- `telehealth_services`
- `spanish_speakers`
- `at_home_services`
- `in_clinic_services`
- `in_home_only`
- `service_delivery` (hash with `in_home`, `in_clinic`, `telehealth`)

### Location Fields
- `id` (for existing locations)
- `name`
- `address_1`
- `address_2`
- `city`
- `state`
- `zip`
- `phone` 📞 **Important**: Each location has its own phone field. The primary location's phone is typically used for the main contact phone displayed in the UI.
- `email`
- `in_home_waitlist`
- `in_clinic_waitlist`
- `primary` (boolean - marks location as primary)
- `services` (array of `{id, name}`) - **Preferred format**
- `practice_types` (array of strings like `["ABA Therapy", "Speech Therapy"]`) - **Alternative format, also accepted**

### Other Fields
- `primary_location_id` (integer - ID of primary location)
- `insurance` (array)
- `counties_served` (array with `county_id`)
- `provider_type` (array)
- `provider_attributes` (hash of field_name => value)

## Response Format

### Success (200 OK)

```json
{
  "data": [
    {
      "id": "181",
      "type": "provider",
      "states": ["Utah", "Colorado"],
      "attributes": {
        "name": "Provider Name",
        "primary_location_id": 123,
        "locations": [
          {
            "id": 123,
            "name": "Main Office",
            "address_1": "123 Main St",
            "address_2": "Suite 100",
            "city": "Salt Lake City",
            "state": "UT",
            "zip": "84101",
            "phone": "(555) 123-4567",
            "services": [
              { "id": 1, "name": "ABA Therapy" }
            ],
            "in_home_waitlist": "Contact for availability",
            "in_clinic_waitlist": "No waitlist",
            "primary": true
          }
        ],
        "website": "https://example.com",
        "email": "provider@example.com",
        "phone": "(555) 123-4567",
        // ... other fields
      }
    }
  ]
}
```

### Error (422 Unprocessable Entity)

```json
{
  "errors": ["Name can't be blank", "Email is invalid"]
}
```

### Error (403 Forbidden)

```json
{
  "error": "Access denied. You do not have permission to access this provider."
}
```

### Error (404 Not Found)

```json
{
  "error": "No provider found. Please set an active provider or link a provider to your account."
}
```

## Phone Fields - Two Separate Fields

⚠️ **Important**: There are **TWO separate phone fields** in the system:

1. **Provider-level phone** (`provider.attributes.phone`):
   - Stored in the `providers` table
   - Legacy field, typically not used by the frontend
   - Can be updated via `attributes.phone` in the request

2. **Location-level phone** (`location.phone`):
   - Stored in the `locations` table
   - **This is what the frontend typically uses and updates**
   - Each location can have its own phone number
   - Updated via the `locations` array in the request

**Frontend Implementation Pattern:**
- The Contact & Services tab phone field should update the **primary location's phone** (not the provider-level phone)
- Send the phone in the `locations` array with the primary location's ID
- The backend will update the location's phone field correctly

**Example - Updating Primary Location Phone:**
```json
{
  "data": [
    {
      "attributes": {
        "locations": [
          {
            "id": 123,  // Primary location ID
            "phone": "(555) 987-6543",  // Update the location's phone
            "name": "Main Office",
            // ... other location fields
          }
        ]
      }
    }
  ]
}
```

## Important Behaviors

### 1. Locations Update Behavior (CRITICAL)

⚠️ **The `update_locations` method uses a "replace all" strategy:**

- If you include `locations` in the request, **ALL existing locations not included will be DELETED**
- You **MUST** include ALL existing locations when updating
- If you're not updating locations, simply don't include the `locations` field

### 1a. Services/Practice Types Update Behavior

✅ **The backend now accepts both formats and handles empty arrays safely:**

- **Format 1 (Preferred)**: `services: [{id: 1, name: "ABA Therapy"}]`
- **Format 2 (Alternative)**: `practice_types: ["ABA Therapy", "Speech Therapy"]`
- **If `services` or `practice_types` is not provided** → existing services are preserved
- **If `services: []` or `practice_types: []` is sent** → existing services are preserved (empty array = preserve, not clear)
- **To update services**: Send the complete list of services you want
- **To remove all services**: This requires explicit backend support (currently preserves if empty)

**Example - What happens:**

**Before:**
- Location 1 (ID: 100)
- Location 2 (ID: 101)
- Location 3 (ID: 102)

**Request with:**
```json
{
  "locations": [
    { "id": 100, "name": "Updated Location 1" },
    { "id": 101, "name": "Updated Location 2" }
    // Location 3 is missing!
  ]
}
```

**After:**
- Location 1 (ID: 100) - ✅ UPDATED
- Location 2 (ID: 101) - ✅ UPDATED
- Location 3 (ID: 102) - ❌ **DELETED** (not in request)

### 2. Primary Location

You can set the primary location in two ways:

**Option A: Using `primary_location_id`**
```json
{
  "primary_location_id": 123
}
```

**Option B: Using `primary: true` flag on location**
```json
{
  "locations": [
    { "id": 123, "primary": true },
    { "id": 124, "primary": false }
  ]
}
```

If both are provided, `primary_location_id` takes precedence.

### 3. Conditional Updates

The endpoint only updates fields that are provided:
- If `locations` is not included → locations remain unchanged
- If `insurance` is not included → insurance remains unchanged
- If `counties_served` is not included → counties remain unchanged
- etc.

### 4. Provider Reload

After updating, the provider is reloaded with all associations to ensure fresh data:
- Locations are fresh from database
- `primary_location_id` reflects current state
- All associations properly loaded

## Code Reference

**Controller**: `app/controllers/api/v1/provider_self_controller.rb`

**Key Methods**:
- `update` - Main update action
- `set_provider` - Sets @provider from user's active/primary provider
- `provider_params` - Permits basic provider fields
- `multipart_provider_params` - Permits fields for multipart requests
- `update_provider_attributes` - Handles category-specific attributes

**Model Methods Used**:
- `provider.update_locations(locations, primary_location_id:)` - Updates locations
- `provider.update_provider_insurance(insurance)` - Updates insurance
- `provider.update_counties_from_array(county_ids)` - Updates counties
- `provider.update_practice_types(types)` - Updates practice types

## Example Requests

### Update Basic Info Only
```bash
PATCH /api/v1/provider_self
Authorization: Bearer 3
Content-Type: application/json

{
  "data": [{
    "attributes": {
      "name": "Updated Provider Name",
      "phone": "(555) 999-8888"
    }
  }]
}
```

### Update Locations (Must Include All)
```bash
PATCH /api/v1/provider_self
Authorization: Bearer 3
Content-Type: application/json

{
  "data": [{
    "attributes": {
      "locations": [
        { "id": 123, "name": "Updated Location 1", "primary": true },
        { "id": 124, "name": "Updated Location 2", "primary": false },
        { "name": "New Location", "phone": "(555) 111-2222", "primary": false }
      ],
      "primary_location_id": 123
    }
  }]
}
```

### Update Logo
```bash
PATCH /api/v1/provider_self
Authorization: Bearer 3
Content-Type: multipart/form-data

name: Provider Name
logo: [binary file data]
```

## Notes

- The endpoint automatically uses the authenticated user's active provider or primary provider
- No provider ID needs to be specified in the URL (it's a singular resource)
- All updates are logged for debugging
- The response includes the complete updated provider object with all associations

