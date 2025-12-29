# Location Waitlist Options

The `in_home_waitlist` and `in_clinic_waitlist` fields on Location records must use one of the predefined values. Any other value will be rejected by validation.

## Valid Waitlist Options

### In-Home Waitlist Options

These options are available for the `in_home_waitlist` field:

```javascript
const IN_HOME_WAITLIST_OPTIONS = [
  "No waitlist",
  "1-2 weeks",
  "2-4 weeks",
  "1-3 months",
  "3-6 months",
  "6+ months",
  "Not accepting new clients",
  "Contact for availability",
  "No in-home services available at this location"  // Specific to in-home
];
```

### In-Clinic Waitlist Options

These options are available for the `in_clinic_waitlist` field:

```javascript
const IN_CLINIC_WAITLIST_OPTIONS = [
  "No waitlist",
  "1-2 weeks",
  "2-4 weeks",
  "1-3 months",
  "3-6 months",
  "6+ months",
  "Not accepting new clients",
  "Contact for availability"
  // Note: "No in-home services available at this location" is NOT available for in-clinic
];
```

## Backend Implementation

The backend uses `Location::WAITLIST_OPTIONS` which includes all options. The frontend should filter out `"No in-home services available at this location"` when displaying the in-clinic waitlist dropdown.

## Usage

When creating or updating a location, use the appropriate options for each field:

```javascript
// ✅ CORRECT
const location = {
  name: "Main Office",
  address_1: "123 Main St",
  city: "Salt Lake City",
  state: "UT",
  zip: "84101",
  phone: "(801) 555-1234",
  in_home_waitlist: "No in-home services available at this location",  // ✅ Valid for in-home
  in_clinic_waitlist: "1-2 weeks"  // ✅ Valid for in-clinic (NOT the in-home-only option)
};

// ❌ WRONG
const location = {
  // ...
  in_clinic_waitlist: "No in-home services available at this location"  // ❌ Doesn't make sense for in-clinic
};
```

## Frontend Form Implementation

```javascript
// All valid options (includes in-home specific option)
const ALL_WAITLIST_OPTIONS = [
  "No waitlist",
  "1-2 weeks",
  "2-4 weeks",
  "1-3 months",
  "3-6 months",
  "6+ months",
  "Not accepting new clients",
  "Contact for availability",
  "No in-home services available at this location"
];

// In-home waitlist dropdown (all options)
const InHomeWaitlistSelect = ({ value, onChange }) => {
  return (
    <select value={value} onChange={onChange}>
      <option value="">Select waitlist status...</option>
      {ALL_WAITLIST_OPTIONS.map(option => (
        <option key={option} value={option}>{option}</option>
      ))}
    </select>
  );
};

// In-clinic waitlist dropdown (filter out in-home-only option)
const InClinicWaitlistSelect = ({ value, onChange }) => {
  const clinicOptions = ALL_WAITLIST_OPTIONS.filter(
    option => option !== "No in-home services available at this location"
  );
  
  return (
    <select value={value} onChange={onChange}>
      <option value="">Select waitlist status...</option>
      {clinicOptions.map(option => (
        <option key={option} value={option}>{option}</option>
      ))}
    </select>
  );
};
```

## Notes

- Both fields use the same validation rules on the backend (`Location::WAITLIST_OPTIONS`)
- The backend will accept `"No in-home services available at this location"` for `in_clinic_waitlist` (it's technically valid), but it doesn't make logical sense
- **Frontend should filter** this option out of the in-clinic dropdown to prevent user confusion
- Empty strings (`""`) or `null` are allowed (will be treated as blank)
- The backend validation is strict - any value not in the full list will cause a validation error (though normalization will attempt to fix common variations)
