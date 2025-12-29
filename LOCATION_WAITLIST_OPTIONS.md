# Location Waitlist Options

The `in_home_waitlist` and `in_clinic_waitlist` fields on Location records must use one of the following predefined values. Any other value will be rejected by validation.

## Valid Waitlist Options

```javascript
const WAITLIST_OPTIONS = [
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
```

## Usage

When creating or updating a location, use these exact strings:

```javascript
// ✅ CORRECT
const location = {
  name: "Main Office",
  address_1: "123 Main St",
  city: "Salt Lake City",
  state: "UT",
  zip: "84101",
  phone: "(801) 555-1234",
  in_home_waitlist: "No waitlist",  // ✅ Valid option
  in_clinic_waitlist: "1-2 weeks"    // ✅ Valid option
};

// ❌ WRONG
const location = {
  // ...
  in_home_waitlist: "This service isn't provided at this location",  // ❌ Invalid - will be normalized
  in_clinic_waitlist: "Call for availability"  // ❌ Invalid - will be normalized
};
```

## Backend Normalization

The backend will automatically normalize common variations to valid options:

- `"This service isn't provided at this location"` → `"No in-home services available at this location"`
- `"Contact us"` → `"Contact for availability"`
- `"Call for availability"` → `"Contact for availability"`
- `"No wait"` → `"No waitlist"`
- `"Not accepting clients"` → `"Not accepting new clients"`
- Any unrecognized value → `"Contact for availability"` (default)

**However, it's recommended to use the exact valid options to avoid normalization and ensure consistency.**

## Frontend Form Implementation

```javascript
// Example: Dropdown/Select component
const WaitlistSelect = ({ value, onChange, label }) => {
  const WAITLIST_OPTIONS = [
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

  return (
    <select value={value} onChange={onChange}>
      <option value="">Select waitlist status...</option>
      {WAITLIST_OPTIONS.map(option => (
        <option key={option} value={option}>{option}</option>
      ))}
    </select>
  );
};

// Usage
<WaitlistSelect
  value={location.in_home_waitlist}
  onChange={(e) => setLocation({ ...location, in_home_waitlist: e.target.value })}
  label="In-Home Waitlist"
/>
```

## Notes

- Both `in_home_waitlist` and `in_clinic_waitlist` use the same set of options
- The options are case-sensitive - use the exact strings shown above
- Empty strings (`""`) or `null` are allowed (will be treated as blank)
- The backend validation is strict - any value not in this list will cause a validation error (though normalization will attempt to fix common variations)

