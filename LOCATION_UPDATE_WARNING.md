# ⚠️ CRITICAL: Location Update Behavior

## The Problem

The `update_locations` method in the Provider model uses a **"replace all"** strategy. This means:

**If you send locations in an update request, ALL locations not included in that request will be DELETED.**

## How It Works

When you call `provider.update_locations(location_params)`, the method:

1. **Extracts all location IDs** from the `location_params` array
2. **Deletes any existing locations** that are NOT in that list
3. **Updates or creates** locations based on the params

### Example - What Happens:

**Before update:**
- Location 1 (ID: 100)
- Location 2 (ID: 101)  
- Location 3 (ID: 102)

**You send update with:**
```json
{
  "locations": [
    { "id": 100, "name": "Updated Location 1" },
    { "id": 101, "name": "Updated Location 2" }
    // Location 3 is missing!
  ]
}
```

**After update:**
- Location 1 (ID: 100) - UPDATED ✅
- Location 2 (ID: 101) - UPDATED ✅
- Location 3 (ID: 102) - **DELETED** ❌ (because it wasn't in the params)

## Frontend Requirements

### ✅ CORRECT: Always Send ALL Locations

```javascript
// When updating ANY provider data, if you include locations,
// you MUST include ALL existing locations:

const updateProvider = async (providerId, updates) => {
  // 1. First, fetch current provider data
  const currentProvider = await fetch(`/api/v1/providers/${providerId}`).then(r => r.json());
  
  // 2. Merge with updates
  const allLocations = updates.locations || currentProvider.data.attributes.locations;
  
  // 3. Send ALL locations
  await fetch(`/api/v1/providers/${providerId}`, {
    method: 'PATCH',
    body: JSON.stringify({
      data: {
        attributes: {
          ...updates,
          locations: allLocations,  // Always include all locations
          primary_location_id: updates.primary_location_id || currentProvider.data.attributes.primary_location_id
        }
      }
    })
  });
};
```

### ❌ WRONG: Only Sending New/Updated Locations

```javascript
// DON'T DO THIS - will delete other locations!
await fetch(`/api/v1/providers/${providerId}`, {
  method: 'PATCH',
  body: JSON.stringify({
    data: {
      attributes: {
        locations: [newLocation]  // Missing existing locations - they'll be deleted!
      }
    }
  })
});
```

### ✅ CORRECT: Updating Without Changing Locations

```javascript
// If you're NOT updating locations, simply don't include them:
await fetch(`/api/v1/providers/${providerId}`, {
  method: 'PATCH',
  body: JSON.stringify({
    data: {
      attributes: {
        name: "New Name",
        // Don't include locations if you're not changing them
      }
    }
  })
});
```

## Safe Update Pattern

```javascript
// Safe pattern for updating provider data:

async function updateProviderSafely(providerId, updates) {
  // Step 1: Fetch current state
  const response = await fetch(`/api/v1/providers/${providerId}`);
  const { data } = await response.json();
  const currentAttributes = data.attributes;
  
  // Step 2: Prepare update payload
  const updatePayload = {
    data: {
      attributes: {
        // Include all non-location updates
        ...updates,
        
        // Only include locations if explicitly updating them
        // If included, MUST include ALL locations (merge existing with new)
        ...(updates.locations && {
          locations: [
            // Include all existing locations that aren't being updated
            ...currentAttributes.locations.filter(loc => 
              !updates.locations.find(updateLoc => 
                (updateLoc.id || updateLoc["id"]) === loc.id
              )
            ),
            // Include updated/new locations
            ...updates.locations
          ],
          // Preserve or update primary_location_id
          primary_location_id: updates.primary_location_id || currentAttributes.primary_location_id
        })
      }
    }
  };
  
  // Step 3: Send update
  return fetch(`/api/v1/providers/${providerId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(updatePayload)
  });
}
```

## Summary

- ✅ **Include locations in update** = You're replacing ALL locations with what you send
- ✅ **Don't include locations in update** = Locations remain unchanged
- ❌ **Include only some locations** = Other locations get deleted

This is by design to allow the frontend to manage the complete state, but it requires the frontend to always send the complete set of locations when updating.

