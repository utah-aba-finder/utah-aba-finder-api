# Registration to Provider Data Mapping

## Overview

When a provider registration is approved, the data from `submitted_data` is mapped to the `Provider` model and its associated records. This document explains what data is saved where.

## Data Mapping

### 1. Basic Provider Fields (Direct Mapping)

These fields are saved directly to the `providers` table:

- `provider_name` → `providers.name`
- `email` → `providers.email`
- `category` → `providers.category`
- `website` → `providers.website` (from `submitted_data['website']`)
- `contact_phone` → `providers.phone` (from `submitted_data['contact_phone']` or `submitted_data['phone']`)
- `pricing` → `providers.cost` (from `submitted_data['pricing']` or `submitted_data['cost']`)
- `waitlist_status` → `providers.waitlist` (from `submitted_data['waitlist_status']` or `submitted_data['waitlist']`)
- Age groups → `providers.min_age` and `providers.max_age` (extracted from `submitted_data['age_groups']` or `submitted_data['age_range_served']`)
- `service_delivery` → `providers.service_delivery` (parsed into `{ in_home, in_clinic, telehealth }`)
- `spanish_speakers` → `providers.spanish_speakers`

### 2. Category-Specific Fields (Provider Attributes)

**All category-specific fields are saved to `provider_attributes` table**, including:

- **Credentials/Qualifications** → `provider_attributes` with `category_field.name = "Credentials/Qualifications"`
- **Program Types** → `provider_attributes` with `category_field.name = "Program Types"`
- **Age Groups** → `provider_attributes` with `category_field.name = "Age Groups"`
- **Delivery Format** → `provider_attributes` with `category_field.name = "Delivery Format"`
- **Integration Options** → `provider_attributes` with `category_field.name = "Integration Options"`
- **Pricing** → `provider_attributes` with `category_field.name = "Pricing"`
- **Parent/Caregiver Support** → `provider_attributes` with `category_field.name = "Parent/Caregiver Support"`
- And any other fields defined in the `CategoryField` model for that category

### 3. Associated Records

- **Practice Types**: Created from `service_types` or `program_types` in `submitted_data`
- **Insurance**: Created via `InsuranceService.link_insurances_to_provider()` from `submitted_data['insurance']` or `submitted_data['insurance_accepted']`
- **Counties**: Created from `submitted_data['counties']` or `submitted_data['counties_served']` or `submitted_data['service_areas']`
- **Locations**: Created from `submitted_data['primary_address']`

## Accessing Provider Attributes

### Via API

When fetching a provider via `GET /api/v1/providers/:id`, the response includes:

```json
{
  "data": [{
    "attributes": {
      "provider_attributes": {
        "Credentials/Qualifications": "Non-Profit Organization",
        "Program Types": "Early Learning Programs, PreK-2 Curriculum",
        "Age Groups": "3-8 (PreK-2nd Grade)",
        // ... other fields
      },
      "category_fields": [
        {
          "id": 100,
          "name": "Program Types",
          "slug": "program_types",
          "field_type": "multi_select",
          // ... field definition
        }
        // ... other field definitions
      ]
    }
  }]
}
```

### Via Rails Console

```ruby
provider = Provider.find(provider_id)

# Get all provider attributes
provider.provider_attributes.each do |attr|
  puts "#{attr.category_field.name}: #{attr.value}"
end

# Get a specific attribute
credentials = provider.get_attribute_value("Credentials/Qualifications")
puts credentials # => "Non-Profit Organization"
```

## Important Notes

1. **All registration fields ARE saved**: Category-specific fields like "Credentials/Qualifications" are saved to `provider_attributes`, not directly to the `providers` table.

2. **Nested data structure**: Registration data is nested under the category key (e.g., `submitted_data['educational_programs']`), but the approval process flattens this using `get_submitted_data()`.

3. **Provider attributes are always included** in single provider API responses (`GET /api/v1/providers/:id`), but NOT in list responses (`GET /api/v1/providers`) for performance reasons.

4. **Field names must match**: The field names in `submitted_data` must match the `CategoryField.name` values for the data to be saved correctly.

## Example: Educational Programs Registration

**Registration `submitted_data`:**
```json
{
  "educational_programs": {
    "credentials_qualifications": ["Non-Profit Organization"],
    "program_types": ["Early Learning Programs", "PreK-2 Curriculum"],
    "age_groups": ["3-8 (PreK-2nd Grade)"],
    "pricing": "Free"
  }
}
```

**After approval, stored as:**
- `providers.cost` = "Free"
- `provider_attributes` records:
  - `category_field.name` = "Credentials/Qualifications", `value` = "Non-Profit Organization"
  - `category_field.name` = "Program Types", `value` = "Early Learning Programs, PreK-2 Curriculum"
  - `category_field.name` = "Age Groups", `value` = "3-8 (PreK-2nd Grade)"
  - `category_field.name` = "Pricing", `value` = "Free"

