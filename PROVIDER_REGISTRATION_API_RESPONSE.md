# Provider Registration API Response Structure

## Endpoints

### GET `/api/v1/provider_registrations` (Index)
Returns a list of all provider registrations (super admin only).

### GET `/api/v1/provider_registrations/:id` (Show)
Returns a single provider registration.

### POST `/api/v1/provider_registrations` (Create)
Creates a new provider registration.

---

## Response Structure

### Index Response (Array)
```json
{
  "data": [
    {
      "id": 133,
      "type": "provider_registration",
      "attributes": {
        "email": "tiasmith@waterford.org",
        "provider_name": "Waterford.org",
        "category": "educational_programs",
        "status": "approved",  // "pending", "approved", "rejected"
        "submitted_data": {
          "educational_programs": {
            "pricing": "Free!",
            "website": "https://waterford.org",
            "age_groups": ["4-5 years", "5-6 years", "6-8 years"],
            "contact_phone": "",
            "program_types": ["Early Learning Programs", "PreK-2 Curriculum"],
            "service_areas": ["Alabama", "Alaska", "Arizona", ...],
            "delivery_format": "Online only (via web browser)",
            "primary_address": {
              "street": "4246 Riverboat Rd",
              "suite": "",
              "city": "Taylorsville",
              "state": "Utah",
              "zip": "84123",
              "phone": ""
            },
            "waitlist_status": "Currently accepting clients",
            "additional_notes": "",
            "service_delivery": {
              "in_home": true,
              "in_clinic": false,
              "telehealth": true
            },
            "integration_options": "Integrated with therapies...",
            "parent_caregiver_support": true,
            "credentials_qualifications": "ISO/IEC Certified"
          }
        },
        "submitted_data_summary": {
          // Same structure as submitted_data, but arrays are joined with commas
          "educational_programs": {
            "program_types": "Early Learning Programs, PreK-2 Curriculum",
            "age_groups": "4-5 years, 5-6 years, 6-8 years",
            // ... other fields
          }
        },
        "admin_notes": null,
        "reviewed_at": "2025-12-04 20:00:29 UTC",
        "rejection_reason": null,
        "is_processed": true,
        "created_at": "2025-12-04 19:26:29 UTC",
        "updated_at": "2025-12-04 19:26:29 UTC"
      },
      "relationships": {
        "reviewed_by": {
          "id": 50,
          "email": "williamsonjordan05@gmail.com"
        }
        // or null if not reviewed yet
      }
    }
  ]
}
```

### Show Response (Single Object)
```json
{
  "id": 133,
  "type": "provider_registration",
  "attributes": {
    // Same structure as above
  },
  "relationships": {
    // Same structure as above
  }
}
```

---

## Key Points for Frontend

### 1. **Nested `submitted_data` Structure**
The `submitted_data` is nested under the category key:
- For `educational_programs`: `submitted_data.educational_programs`
- For `autism_evaluations`: `submitted_data.autism_evaluations`
- For `aba_therapy`: `submitted_data.aba_therapy`

**Example Access:**
```javascript
const registration = response.data[0]; // or response for show endpoint
const category = registration.attributes.category; // "educational_programs"
const categoryData = registration.attributes.submitted_data[category];
// Now you can access: categoryData.program_types, categoryData.age_groups, etc.
```

### 2. **Status Values**
- `"pending"` - Not yet reviewed
- `"approved"` - Approved and provider/user created
- `"rejected"` - Rejected by admin

### 3. **`submitted_data_summary` vs `submitted_data`**
- `submitted_data`: Raw data with arrays preserved
- `submitted_data_summary`: Arrays are joined into comma-separated strings (useful for display)

### 4. **Educational Programs Specific Fields**
When `category === "educational_programs"`, the nested data includes:
- `program_types`: Array of program types
- `age_groups`: Array of age ranges
- `delivery_format`: String
- `integration_options`: String
- `parent_caregiver_support`: Boolean
- `credentials_qualifications`: String
- `pricing`: String
- `primary_address`: Object with address fields
- `service_delivery`: Object with `{ in_home, in_clinic, telehealth }`
- `service_areas`: Array of state names
- `waitlist_status`: String
- `additional_notes`: String

### 5. **Relationships**
- `reviewed_by`: Object with `id` and `email` if reviewed, `null` if not reviewed

---

## Example Frontend Usage

```javascript
// Fetch registrations
const response = await fetch('/api/v1/provider_registrations', {
  headers: {
    'Authorization': `Bearer ${adminUserId}`
  }
});
const { data } = await response.json();

// Access registration data
data.forEach(registration => {
  const { attributes } = registration;
  const category = attributes.category;
  const categoryData = attributes.submitted_data[category];
  
  console.log('Provider:', attributes.provider_name);
  console.log('Email:', attributes.email);
  console.log('Status:', attributes.status);
  console.log('Program Types:', categoryData.program_types);
  console.log('Age Groups:', categoryData.age_groups);
  // etc.
});
```

---

## Notes

- The `submitted_data` structure varies by category
- Arrays in `submitted_data` are preserved as arrays
- Arrays in `submitted_data_summary` are joined with commas
- `is_processed` indicates if the registration has been processed (approved/rejected)
- `reviewed_at` is set when the registration is reviewed
- `admin_notes` and `rejection_reason` are set during review

