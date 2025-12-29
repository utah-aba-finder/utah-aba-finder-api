# Frontend Guide: Primary Location Implementation

## Overview

The backend now supports a **database-backed primary location** system. The primary location is stored in `providers.primary_location_id` (a foreign key to the `locations` table), ensuring stable and reliable primary location tracking.

## API Response Format

When fetching a provider, the response now includes:

1. **`primary_location_id`** - The ID of the primary location (top-level attribute)
2. **`primary: true/false`** - Boolean flag on each location object indicating if it's the primary location

### Example Response:

```json
{
  "data": {
    "id": "123",
    "type": "provider",
    "attributes": {
      "primary_location_id": 2347,
      "locations": [
        {
          "id": 2347,
          "name": "Utah Location",
          "primary": true,
          // ... other location fields
        },
        {
          "id": 2348,
          "name": "Colorado Location",
          "primary": false,
          // ... other location fields
        }
      ]
    }
  }
}
```

## Frontend Requirements

### 1. Reading Primary Location

**Recommended Approach:**
- Use `provider.attributes.primary_location_id` as the source of truth
- The `primary: true/false` flag on each location is provided for convenience but should match `primary_location_id`

**Example:**
```javascript
const primaryLocationId = provider.attributes.primary_location_id;
const primaryLocation = provider.attributes.locations.find(
  loc => loc.id === primaryLocationId
);
```

### 2. Setting/Updating Primary Location

**When updating locations, send `primary_location_id` as a top-level attribute:**

```javascript
// ✅ CORRECT: Send primary_location_id separately
const updatePayload = {
  data: {
    attributes: {
      locations: [
        { id: 2347, name: "Utah Location", primary: false },
        { id: 2348, name: "Colorado Location", primary: false },
        { id: 2349, name: "Nevada Location", primary: true } // New location
      ],
      primary_location_id: 2349  // Set Nevada as primary
    }
  }
};
```

**Alternative (backward compatible):** You can also set `primary: true` on a location object. The backend will:
1. First check for `primary_location_id` attribute
2. If not provided, check for a location with `primary: true`
3. Set that location as primary

**Example using `primary: true`:**
```javascript
// ✅ ALSO WORKS: Use primary: true flag
const updatePayload = {
  data: {
    attributes: {
      locations: [
        { id: 2347, name: "Utah Location", primary: false },
        { id: 2348, name: "Colorado Location", primary: false },
        { id: 2349, name: "Nevada Location", primary: true } // Backend will detect this
      ]
      // primary_location_id can be omitted if using primary: true
    }
  }
};
```

### 3. Adding a New Location (While Preserving Primary)

**✅ CORRECT: Include ALL locations + set primary_location_id**

```javascript
// Current state: Utah (2347) is primary
// Adding new "Nevada" location, keeping Utah as primary

const existingLocations = provider.attributes.locations;
const newLocation = {
  name: "Gracious Growth ABA Nevada",
  phone: "(702)555-1234",
  // ... other fields
  primary: false  // New location is NOT primary
};

const updatePayload = {
  data: {
    attributes: {
      locations: [
        ...existingLocations.map(loc => ({
          ...loc,
          primary: loc.id === provider.attributes.primary_location_id
        })),
        newLocation
      ],
      primary_location_id: provider.attributes.primary_location_id  // Preserve existing primary
    }
  }
};
```

### 4. Changing Primary Location

**✅ CORRECT: Send all locations + update primary_location_id**

```javascript
// Changing primary from Utah (2347) to Colorado (2348)

const updatePayload = {
  data: {
    attributes: {
      locations: [
        { id: 2347, name: "Utah Location", primary: false },
        { id: 2348, name: "Colorado Location", primary: true },  // New primary
        { id: 2349, name: "Nevada Location", primary: false }
      ],
      primary_location_id: 2348  // Set Colorado as primary
    }
  }
};
```

### 5. Critical Rules

1. **Always send ALL locations** when updating - the backend uses this to determine which locations to keep/delete
2. **Only ONE location should have `primary_location_id` set** (or `primary: true` if using that method)
3. **Preserve `primary_location_id` when adding new locations** - explicitly send it in the update request
4. **Primary location persists** - it won't change unless you explicitly set a new one

## Migration Notes

### Before (Fragile - Array Index Based):
```javascript
// ❌ OLD APPROACH - Don't use this anymore
const primaryLocation = locations[0]; // First location was "primary"
```

### After (Stable - Database Backed):
```javascript
// ✅ NEW APPROACH - Use primary_location_id
const primaryLocationId = provider.attributes.primary_location_id;
const primaryLocation = locations.find(loc => loc.id === primaryLocationId);
```

## Backend Behavior

- **Primary location is stored in database** - `providers.primary_location_id` (FK to `locations`)
- **Validation ensures** primary location belongs to the provider
- **Automatic cleanup** - if primary location is deleted, `primary_location_id` is cleared
- **Deterministic ordering** - locations are ordered by `:id` for consistency, but primary is determined by `primary_location_id`
- **Backward compatible** - can use `primary: true` flag if `primary_location_id` not provided

## Example: Complete Update Flow

```javascript
// User adds a new location and wants to make it primary
const addNewPrimaryLocation = (provider, newLocationData) => {
  const allLocations = [
    ...provider.attributes.locations.map(loc => ({
      ...loc,
      primary: false  // Existing locations are no longer primary
    })),
    {
      ...newLocationData,
      primary: true  // New location is primary
    }
  ];

  const updatePayload = {
    data: {
      attributes: {
        locations: allLocations,
        // Option 1: Explicitly set primary_location_id after creation
        // (You'll need to know the new location's ID, or use primary: true method)
        // Option 2: Use primary: true flag (backend will handle it)
      }
    }
  };

  // For new locations, use primary: true method since ID isn't known yet
  // Backend will set primary_location_id to the new location's ID after creation
  updateProvider(updatePayload);
};
```

## Summary

- ✅ Use `primary_location_id` as the source of truth
- ✅ Always send ALL locations when updating
- ✅ Explicitly set `primary_location_id` (or use `primary: true`) when changing primary
- ✅ Preserve `primary_location_id` when adding new locations
- ✅ Primary location is stable and won't change unless explicitly updated

