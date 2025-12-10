# Provider Structure & API Responses

## Overview

After integrating provider registration data, the provider structure now includes:
1. **Standard provider fields** (stored directly on `providers` table)
2. **Category-specific attributes** (stored in `provider_attributes` table)
3. **Category field definitions** (from `category_fields` table)

## API Response Structure

### Single Provider Response (`GET /api/v1/providers/:id`)

**Includes ALL fields including category-specific attributes:**

```json
{
  "data": [{
    "id": 1195,
    "type": "provider",
    "states": ["Utah"],
    "attributes": {
      // === STANDARD PROVIDER FIELDS ===
      "name": "Waterford.org",
      "email": "contact@waterford.org",
      "website": "https://waterford.org",
      "cost": "Free",
      "waitlist": "Currently accepting clients",
      "status": "approved",
      
      // === CATEGORY & TYPE ===
      "category": "educational_programs",              // Slug identifier
      "category_name": "Educational Programs",        // Display name
      "provider_type": [                              // Practice types
        {
          "id": 142,
          "name": "Educational Programs"
        }
      ],
      
      // === LOCATIONS ===
      "locations": [
        {
          "id": 123,
          "name": "Main Office",
          "address_1": "4246 Riverboat Rd",
          "address_2": "",
          "city": "Taylorsville",
          "state": "Utah",
          "zip": "84123",
          "phone": "",
          "services": [
            {
              "id": 142,
              "name": "Educational Programs"
            }
          ],
          "in_home_waitlist": false,
          "in_clinic_waitlist": false
        }
      ],
      
      // === INSURANCE ===
      "insurance": [
        {
          "name": "Blue Cross Blue Shield",
          "id": 5,
          "accepted": true
        }
      ],
      
      // === SERVICE AREAS ===
      "counties_served": [
        {
          "county_id": 1,
          "county_name": "Salt Lake"
        }
      ],
      
      // === AGE & SERVICES ===
      "min_age": 4,
      "max_age": 8,
      "telehealth_services": true,
      "spanish_speakers": "Yes",
      "at_home_services": true,
      "in_clinic_services": false,
      "in_home_only": false,
      "service_delivery": {
        "in_home": true,
        "in_clinic": false,
        "telehealth": true
      },
      
      // === MEDIA ===
      "logo": "https://asl-logos.s3.amazonaws.com/...",
      "logo_url": "https://asl-logos.s3.amazonaws.com/...",  // Backward compatible
      "updated_last": "2025-12-09T15:20:47.000Z",
      
      // === CATEGORY-SPECIFIC ATTRIBUTES (NEW) ===
      // These are ONLY included in single provider requests
      "provider_attributes": {
        "Program Types": "Early Learning Programs, PreK-2 Curriculum",
        "Credentials/Qualifications": "ISO/IEC Certified",
        "Age Groups": "4-5 years, 5-6 years, 6-8 years",
        "Delivery Format": "Online only (via web browser)",
        "Integration Options": "Integrated with therapies and early childhood development programs.",
        "Pricing": "Free!",
        "Parent/Caregiver Support": "true"
      },
      
      // === CATEGORY FIELD DEFINITIONS (NEW) ===
      // These define the schema/available fields for this category
      "category_fields": [
        {
          "id": 100,
          "name": "Program Types",
          "slug": "program_types",
          "field_type": "multi_select",
          "required": true,
          "options": {
            "choices": [
              "Early Learning Programs",
              "PreK-2 Curriculum",
              "K-12 Curriculum",
              "Adult Education"
            ]
          },
          "display_order": 1,
          "help_text": "Types of educational programs offered"
        },
        {
          "id": 101,
          "name": "Credentials/Qualifications",
          "slug": "credentials_qualifications",
          "field_type": "text",
          "required": false,
          "options": {},
          "display_order": 2,
          "help_text": "Provider credentials and qualifications"
        }
        // ... more field definitions
      ]
    }
  }]
}
```

### Provider List Response (`GET /api/v1/providers`)

**Does NOT include `provider_attributes` or `category_fields` for performance:**

```json
{
  "data": [
    {
      "id": 1195,
      "type": "provider",
      "states": ["Utah"],
      "attributes": {
        // All standard fields included
        "name": "Waterford.org",
        "category": "educational_programs",
        "category_name": "Educational Programs",
        "provider_type": [...],
        "locations": [...],
        "insurance": [...],
        "counties_served": [...],
        // ... all other standard fields
        
        // ❌ provider_attributes - NOT included
        // ❌ category_fields - NOT included
      }
    }
  ]
}
```

## Data Storage Structure

### 1. Standard Provider Fields

Stored directly in `providers` table:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Provider name |
| `email` | string | Contact email |
| `website` | string | Website URL |
| `phone` | string | Contact phone |
| `cost` | string | Pricing information |
| `waitlist` | string | Waitlist status |
| `category` | string | Category slug (e.g., "educational_programs") |
| `min_age` | integer | Minimum age served |
| `max_age` | integer | Maximum age served |
| `telehealth_services` | boolean | Offers telehealth |
| `spanish_speakers` | string | Spanish language support |
| `at_home_services` | boolean | Offers in-home services |
| `in_clinic_services` | boolean | Offers in-clinic services |
| `service_delivery` | jsonb | `{in_home: true, in_clinic: false, telehealth: true}` |
| `status` | string | Provider status |

### 2. Category-Specific Attributes

Stored in `provider_attributes` table (linked to `category_fields`):

| Table | Field | Description |
|-------|-------|-------------|
| `provider_attributes` | `provider_id` | Links to provider |
| `provider_attributes` | `category_field_id` | Links to field definition |
| `provider_attributes` | `value` | The actual value (string) |

**Example:**
- Provider ID: 1195
- Category Field: "Program Types" (ID: 100)
- Value: "Early Learning Programs, PreK-2 Curriculum"

### 3. Category Field Definitions

Stored in `category_fields` table:

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Field ID |
| `name` | string | Display name (e.g., "Program Types") |
| `slug` | string | URL-friendly identifier (e.g., "program_types") |
| `field_type` | string | Type: "text", "multi_select", "select", "boolean", etc. |
| `required` | boolean | Is this field required? |
| `options` | jsonb | Field options (choices, validation, etc.) |
| `display_order` | integer | Order for display |
| `help_text` | string | Help text for users |

## Key Changes from Registration Integration

### ✅ What's New:

1. **`provider_attributes`** - Hash of category-specific field values
   - Only in single provider responses
   - Format: `{"Field Name": "value"}`

2. **`category_fields`** - Array of field definitions
   - Only in single provider responses
   - Defines what fields are available for this category
   - Includes field types, options, validation rules

3. **`category_name`** - Display name for the category
   - Derived from `provider_category.name`

### 📋 Standard Fields (Unchanged):

- All existing fields remain the same
- Locations, insurance, counties, etc. work as before
- Backward compatible with existing frontend code

## Accessing Provider Attributes in Code

### In Rails:

```ruby
provider = Provider.find(1195)

# Get a specific attribute value
program_types = provider.get_attribute_value("Program Types")
# => "Early Learning Programs, PreK-2 Curriculum"

# Get all attributes
provider.provider_attributes.each do |attr|
  puts "#{attr.category_field.name}: #{attr.value}"
end

# Get category fields
provider.category_fields.each do |field|
  puts "#{field.name} (#{field.field_type})"
end
```

### In Frontend (JavaScript):

```javascript
// Single provider response
const response = await fetch('/api/v1/providers/1195');
const data = await response.json();

const provider = data.data[0].attributes;

// Standard fields
console.log(provider.name);           // "Waterford.org"
console.log(provider.category);       // "educational_programs"
console.log(provider.category_name);  // "Educational Programs"

// Category-specific attributes (only in single provider)
if (provider.provider_attributes) {
  console.log(provider.provider_attributes["Program Types"]);
  // => "Early Learning Programs, PreK-2 Curriculum"
}

// Category field definitions (only in single provider)
if (provider.category_fields) {
  provider.category_fields.forEach(field => {
    console.log(`${field.name}: ${field.field_type}`);
  });
}
```

## Important Notes

1. **Performance**: `provider_attributes` and `category_fields` are only included in single provider requests to avoid memory issues with large lists.

2. **Field Names**: Attribute keys in `provider_attributes` match the `category_field.name` exactly (e.g., "Program Types", not "program_types").

3. **Values**: All attribute values are stored as strings. Arrays are joined with commas (e.g., `["A", "B"]` → `"A, B"`).

4. **Category Fields**: The `category_fields` array shows what fields are available for this provider's category, even if the provider doesn't have a value set.

5. **Backward Compatibility**: All existing fields and response structure remain unchanged. The new fields are additive.

## Migration from Registration Data

When a registration is approved, data flows like this:

```
Registration submitted_data
  ↓
Provider basic fields (name, email, website, etc.)
  ↓
Provider attributes (category-specific fields)
  ↓
Associated records (locations, insurance, counties, practice_types)
```

See `REGISTRATION_TO_PROVIDER_DATA_MAPPING.md` for detailed mapping information.

