# API Call for Creating Educational Programs Provider

## Endpoint
`POST /api/v1/admin/providers`

## Headers
```javascript
{
  'Content-Type': 'application/json',
  'Authorization': 'Bearer YOUR_USER_ID' // Admin user ID
}
```

## Request Body Example

```javascript
const createEducationalProgramProvider = async (providerData) => {
  const response = await fetch('https://utah-aba-finder-api-c9d143f02ce8.herokuapp.com/api/v1/admin/providers', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${adminUserId}` // Replace with actual admin user ID
    },
    body: JSON.stringify({
      data: [{
        attributes: {
          // Basic Provider Info
          name: "Example Learning Programs",
          email: "contact@examplelearning.org",
          website: "https://www.examplelearning.org",
          phone: "(801) 555-1234",
          
          // Category - IMPORTANT: Use "educational_programs"
          category: "educational_programs",
          
          // Service Delivery (online only)
          in_home_only: true, // Required: true for online-only providers
          service_delivery: {
            in_home: false,
            in_clinic: false,
            telehealth: true
          },
          
          // Age Range
          min_age: 3,
          max_age: 8, // PreK-2nd grade
          
          // Cost/Waitlist
          cost: "Free" // or "Contact us", "Sliding Scale", etc.
          waitlist: "Contact us",
          
          // Service Types
          at_home_services: "Online learning programs for PreK-2nd grade",
          in_clinic_services: "N/A - Online only",
          telehealth_services: "Online learning programs, live sessions, and self-paced content",
          spanish_speakers: "Unknown", // or "Yes", "No"
          
          // Status (will be set to approved automatically by admin endpoint)
          status: "approved",
          
          // Practice Types (optional - can add "Coaching/Mentoring" if applicable)
          provider_type: [
            { name: "Coaching/Mentoring" } // Optional
          ],
          
          // Counties Served (optional - can be empty array for online providers)
          counties_served: [], // or specify county IDs if they serve specific areas
          
          // Insurance (optional - many educational programs don't accept insurance)
          insurance: [] // or specify insurance IDs if applicable
        }
      }]
    })
  });
  
  return await response.json();
};
```

## Category-Specific Fields

After creating the provider, you'll need to update the category-specific fields using the provider attributes endpoint. These fields are specific to the "Educational Programs" category:

```javascript
// Example: Update category-specific attributes
// Note: You'll need to get the category field IDs first, or use the provider registration endpoint
// which handles this automatically

// The category fields available are:
// - Program Types (multi_select)
// - Credentials/Qualifications (multi_select)
// - Age Groups (multi_select)
// - Delivery Format (multi_select)
// - Integration Options (multi_select)
// - Pricing (multi_select)
// - Parent/Caregiver Support (boolean)
```

## Simplified Example (Minimal Required Fields)

```javascript
const minimalProvider = {
  data: [{
    attributes: {
      name: "Example Learning Programs",
      email: "contact@examplelearning.org",
      category: "educational_programs",
      in_home_only: true,
      service_delivery: {
        in_home: false,
        in_clinic: false,
        telehealth: true
      },
      min_age: 3,
      max_age: 8,
      status: "approved"
    }
  }]
};
```

## Notes

1. **Category**: Must be `"educational_programs"` (the slug we created)
2. **in_home_only**: Set to `true` for online-only providers (no physical location required)
3. **service_delivery**: Set `telehealth: true` since it's online-only
4. **Locations**: Not required for online-only providers (`in_home_only: true`)
5. **Counties**: Can be empty array for online providers serving all areas
6. **Insurance**: Many educational programs don't accept insurance, so can be empty

## Alternative: Use Provider Registration Endpoint

If you want to use the public registration endpoint (which handles category fields automatically):

```javascript
POST /api/v1/provider_registrations
```

This endpoint will automatically create provider attributes based on the category fields.

