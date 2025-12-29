# Waitlist Fields Consistency Guide

## Current State

### Registration Form
- **Does NOT collect waitlist fields** - Locations are created with database defaults
- `in_home_waitlist` and `in_clinic_waitlist` default to `"Contact for availability"`

### Super Admin Provider Creation Form
- **Should collect waitlist fields** - But currently may be using incorrect format
- Should use **string dropdowns** with `Location::WAITLIST_OPTIONS`
- **NOT booleans** - Waitlist fields are strings, not boolean

### Location Model
- Both `in_home_waitlist` and `in_clinic_waitlist` are **text fields** (not boolean)
- Must use one of the predefined string options from `Location::WAITLIST_OPTIONS`
- Validation requires exact match to valid options

## Valid Waitlist Options

### All Options (In-Home Waitlist)

```javascript
const ALL_WAITLIST_OPTIONS = [
  "No waitlist",
  "1-2 weeks",
  "2-4 weeks",
  "1-3 months",
  "3-6 months",
  "6+ months",
  "Not accepting new clients",
  "Contact for availability",
  "No in-home services available at this location"  // Only for in_home_waitlist
];
```

### In-Clinic Waitlist Options

For the `in_clinic_waitlist` field, filter out the in-home-specific option:

```javascript
const IN_CLINIC_WAITLIST_OPTIONS = ALL_WAITLIST_OPTIONS.filter(
  option => option !== "No in-home services available at this location"
);
```

**Important:** The backend validates both fields against the full `WAITLIST_OPTIONS` list, but the frontend should filter out `"No in-home services available at this location"` from the in-clinic dropdown since it doesn't make logical sense for clinic services.

## Recommended Approach

### For Super Admin Provider Creation/Update

**Use string dropdowns for both fields:**

```javascript
// ✅ CORRECT - Use dropdown/select with string values
<select name="in_home_waitlist">
  <option value="">Select waitlist status...</option>
  <option value="No waitlist">No waitlist</option>
  <option value="1-2 weeks">1-2 weeks</option>
  <option value="2-4 weeks">2-4 weeks</option>
  <option value="1-3 months">1-3 months</option>
  <option value="3-6 months">3-6 months</option>
  <option value="6+ months">6+ months</option>
  <option value="Not accepting new clients">Not accepting new clients</option>
  <option value="Contact for availability">Contact for availability</option>
  <option value="No in-home services available at this location">
    No in-home services available at this location
  </option>
</select>

<select name="in_clinic_waitlist">
  {/* Same options as above */}
</select>
```

**NOT booleans:**
```javascript
// ❌ WRONG - Don't use checkboxes/booleans
<input type="checkbox" name="in_home_waitlist" />
<input type="checkbox" name="in_clinic_waitlist" />
```

### For Registration Form

**Option 1: Keep current behavior (recommended)**
- Don't collect waitlist fields in registration
- Use database defaults (`"Contact for availability"`)
- Providers can update waitlist info after approval

**Option 2: Add waitlist fields (optional)**
- Add dropdown fields for `in_home_waitlist` and `in_clinic_waitlist` to registration form
- Use same `WAITLIST_OPTIONS` array
- Update `create_default_location` to use submitted waitlist values
- Default to `"Contact for availability"` if not provided

## Location Object Structure

When sending location data to the API:

```javascript
const location = {
  id: 123,  // Optional - omit for new locations
  name: "Main Office",
  address_1: "123 Main St",
  city: "Salt Lake City",
  state: "UT",
  zip: "84101",
  phone: "(801) 555-1234",
  in_home_waitlist: "No waitlist",      // ✅ String from WAITLIST_OPTIONS
  in_clinic_waitlist: "1-2 weeks",      // ✅ String from WAITLIST_OPTIONS
  services: [
    { id: 115, name: "ABA Therapy" }
  ]
};
```

## Backend Behavior

### Provider Registration
- Locations created via `create_default_location` don't set waitlist fields explicitly
- Database defaults apply: `"Contact for availability"` for both fields

### Super Admin Creation/Update
- Locations created via `update_locations` (uses `Provider#update_locations`)
- Waitlist values are normalized if invalid (see `normalize_waitlist_value` method)
- Invalid values are automatically converted to valid options
- Empty values default to `"Contact for availability"`

## Action Items

1. **Super Admin Form**: Update frontend to use string dropdowns (not booleans) for waitlist fields
2. **Registration Form**: Optional - Can add waitlist fields, or keep current default behavior
3. **Consistency**: Both forms should use the same `WAITLIST_OPTIONS` array for validation/display

