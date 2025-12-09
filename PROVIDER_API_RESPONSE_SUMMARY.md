# Provider API Response - Category Fields & Attributes

## Quick Answer: What the API Returns

**YES** - The API returns category-specific fields and attributes for providers, but **only for single provider requests** (`GET /api/v1/providers/:id`).

## Response Structure

### For Single Provider (`GET /api/v1/providers/:id`):

```json
{
  "data": [{
    "id": 1195,
    "type": "provider",
    "attributes": {
      // Standard provider fields
      "name": "Waterford.org",
      "category": "educational_programs",          // ← Provider type identifier
      "category_name": "Educational Programs",     // ← Display name
      "provider_type": [{ "id": 142, "name": "Educational Programs" }],
      
      // Category-specific data (ONLY in single provider requests)
      "provider_attributes": {                     // ← Actual values set for this provider
        "Program Types": "Early Learning Programs, PreK-2 Curriculum",
        "Age Groups": "3-5 (PreK), 5-7 (Kindergarten-2nd Grade)",
        "Delivery Format": "Online Only",
        "Pricing": "Free",
        "Parent/Caregiver Support": "true"
      },
      
      "category_fields": [                        // ← Field definitions/schema
        {
          "id": 100,
          "name": "Program Types",
          "slug": "program_types",
          "field_type": "multi_select",
          "required": true,
          "options": ["Early Learning Programs", "PreK-2 Curriculum", ...],
          "help_text": "Types of educational programs offered"
        },
        // ... more fields
      ],
      
      // Standard fields continue...
      "website": "...",
      "email": "...",
      // etc.
    }
  }]
}
```

### For Provider List (`GET /api/v1/providers`):

```json
{
  "data": [{
    "attributes": {
      "category": "educational_programs",      // ← Still included
      "category_name": "Educational Programs", // ← Still included
      // BUT provider_attributes and category_fields are NOT included
      // (to avoid memory issues with large lists)
    }
  }]
}
```

## Frontend Rendering Strategy

### 1. Identify Provider Type
Use `category` or `category_name` to determine the provider type:

```javascript
const provider = response.data[0].attributes;

// Option 1: Use category slug
if (provider.category === 'educational_programs') {
  // Render educational programs UI
}

// Option 2: Use category_name
if (provider.category_name === 'Educational Programs') {
  // Render educational programs UI
}

// Option 3: Check provider_type array
if (provider.provider_type.some(pt => pt.name === 'Educational Programs')) {
  // Render educational programs UI
}
```

### 2. Access Category-Specific Data
For single provider views, use `provider_attributes`:

```javascript
// Get specific field values
const programTypes = provider.provider_attributes['Program Types'];
const ageGroups = provider.provider_attributes['Age Groups'];
const pricing = provider.provider_attributes['Pricing'];

// For multi-select fields, split comma-separated values
const programTypesArray = programTypes?.split(', ') || [];
```

### 3. Build Dynamic Forms
Use `category_fields` to dynamically render forms:

```javascript
provider.category_fields.forEach(field => {
  if (field.field_type === 'multi_select') {
    // Render multi-select dropdown with field.options
  } else if (field.field_type === 'boolean') {
    // Render checkbox
  }
  // Use field.required to mark required fields
  // Use field.help_text for tooltips
});
```

## Important Notes

1. **Single Provider Only**: `provider_attributes` and `category_fields` are ONLY in single provider responses (`/api/v1/providers/:id`), NOT in list responses (`/api/v1/providers`)

2. **Category Always Included**: `category` and `category_name` are ALWAYS included in both list and single provider responses

3. **Field Value Format**:
   - Multi-select fields: comma-separated string (e.g., "Option 1, Option 2")
   - Boolean fields: string "true" or "false"
   - Missing fields: may not exist in `provider_attributes` object

4. **For List Views**: Use `category` to filter or group providers, but fetch individual providers to get full details

