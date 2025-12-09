# API Response Structure for Educational Programs Providers

## Endpoint
`GET /api/v1/providers/:id` (single provider)

## Authentication
The `show` endpoint requires authentication (either Bearer token or API key).

## Response Structure

When you fetch a single provider (e.g., `GET /api/v1/providers/1195`), the API returns:

```json
{
  "data": [
    {
      "id": 1195,
      "type": "provider",
      "states": ["Utah"],
      "attributes": {
        "name": "Waterford.org",
        "provider_type": [
          {
            "id": 142,
            "name": "Educational Programs"
          }
        ],
        "category": "educational_programs",
        "category_name": "Educational Programs",
        "provider_attributes": {
          "Program Types": "Early Childhood learning. (Reading, Math and Science)",
          "Credentials/Qualifications": "ISO/IEC Certified",
          "Age Groups": "4-5 years, 5-6 years, 6-8 years",
          "Delivery Format": "Online only (via web browser)",
          "Integration Options": "Integrated with therapies and early childhood development programs.",
          "Pricing": "Free!",
          "Parent/Caregiver Support": "true"
        },
        "category_fields": [
          {
            "id": 100,
            "name": "Program Types",
            "slug": "program_types",
            "field_type": "multi_select",
            "required": true,
            "options": [
              "Early Learning Programs",
              "PreK-2 Curriculum",
              "Reading Programs",
              "Math Programs",
              "Social Skills Programs",
              "Language Development",
              "Cognitive Development",
              "ABA-Integrated Programs",
              "Early Education Support",
              "Homeschool Support",
              "Supplemental Learning",
              "Online Learning Platforms"
            ],
            "display_order": 1,
            "help_text": "Types of educational programs offered"
          },
          {
            "id": 101,
            "name": "Credentials/Qualifications",
            "slug": "credentials_qualifications",
            "field_type": "multi_select",
            "required": true,
            "options": [
              "Licensed Teacher",
              "Certified Educator",
              "Early Childhood Specialist",
              "Special Education Teacher",
              "BCBA/ABA Specialist",
              "Curriculum Developer",
              "Educational Therapist",
              "Learning Specialist",
              "Non-Profit Organization",
              "Accredited Program"
            ],
            "display_order": 2,
            "help_text": "Qualifications and credentials of program providers"
          },
          {
            "id": 102,
            "name": "Age Groups",
            "slug": "age_groups",
            "field_type": "multi_select",
            "required": true,
            "options": [
              "0-3 (Early Intervention)",
              "3-5 (PreK)",
              "5-7 (Kindergarten-2nd Grade)",
              "3-8 (PreK-2nd Grade)",
              "All Ages"
            ],
            "display_order": 3,
            "help_text": "Age ranges served by the program"
          },
          {
            "id": 103,
            "name": "Delivery Format",
            "slug": "delivery_format",
            "field_type": "multi_select",
            "required": true,
            "options": [
              "Online Only",
              "In-Person",
              "Hybrid (Online + In-Person)",
              "Self-Paced Online",
              "Live Online Sessions",
              "Recorded Content",
              "Interactive Platform"
            ],
            "display_order": 4,
            "help_text": "How the program is delivered"
          },
          {
            "id": 104,
            "name": "Integration Options",
            "slug": "integration_options",
            "field_type": "multi_select",
            "required": false,
            "options": [
              "ABA Therapy Integration",
              "Early Education Integration",
              "School Integration",
              "Homeschool Integration",
              "Therapy Integration",
              "Standalone Program"
            ],
            "display_order": 5,
            "help_text": "How the program can be integrated with other services"
          },
          {
            "id": 105,
            "name": "Pricing",
            "slug": "pricing",
            "field_type": "multi_select",
            "required": false,
            "options": [
              "Free",
              "Sliding Scale",
              "Subscription-Based",
              "One-Time Fee",
              "Grant-Funded",
              "Non-Profit Pricing",
              "Flexible pricing based on your circumstances",
              "School District Contracts"
            ],
            "display_order": 6,
            "help_text": "Pricing options available"
          },
          {
            "id": 106,
            "name": "Parent/Caregiver Support",
            "slug": "parent_caregiver_support",
            "field_type": "boolean",
            "required": false,
            "options": {},
            "display_order": 7,
            "help_text": "Includes training or support for parents/caregivers"
          }
        ],
        "website": "https://waterford.org",
        "email": "tiasmith@waterford.org",
        "cost": "Free!",
        "waitlist": "Currently accepting clients",
        "min_age": 4,
        "max_age": 8,
        "telehealth_services": "Yes",
        "service_delivery": {
          "in_home": true,
          "in_clinic": false,
          "telehealth": true
        },
        // ... other standard provider fields
      }
    }
  ]
}
```

## Key Fields for Frontend Rendering

### 1. Provider Type Detection
- `category`: `"educational_programs"` - Use this to identify the provider type
- `category_name`: `"Educational Programs"` - Display name
- `provider_type`: Array of practice types (includes "Educational Programs")

### 2. Category-Specific Data
- `provider_attributes`: Object mapping field names to their values
  - Keys are the field names (e.g., "Program Types", "Age Groups")
  - Values are strings (for multi_select, values are comma-separated)
  - Boolean fields return "true" or "false" as strings

### 3. Available Fields Schema
- `category_fields`: Array of field definitions
  - Use this to:
    - Render dynamic forms for editing
    - Display field labels
    - Show available options for multi_select fields
    - Determine which fields are required

## Frontend Rendering Logic

```javascript
// Example: Render provider based on category
const provider = response.data[0].attributes;

if (provider.category === 'educational_programs') {
  // Render educational programs specific UI
  return (
    <EducationalProgramProvider provider={provider} />
  );
} else if (provider.category === 'aba_therapy') {
  // Render ABA therapy specific UI
  return (
    <ABATherapyProvider provider={provider} />
  );
}

// Access category-specific attributes
const programTypes = provider.provider_attributes['Program Types']?.split(', ') || [];
const ageGroups = provider.provider_attributes['Age Groups']?.split(', ') || [];
const pricing = provider.provider_attributes['Pricing'];
```

## Notes

1. **Single Provider Requests Only**: The `provider_attributes` and `category_fields` are **only included** when fetching a single provider (`GET /api/v1/providers/:id`). They are **not included** in the list endpoint (`GET /api/v1/providers`) to avoid memory issues.

2. **Field Values**: 
   - Multi-select fields store values as comma-separated strings
   - Boolean fields are stored as "true" or "false" strings
   - Empty fields may not be present in `provider_attributes`

3. **Category Fields**: The `category_fields` array tells you:
   - What fields exist for this category
   - What options are available for each field
   - Which fields are required
   - How to render each field type

