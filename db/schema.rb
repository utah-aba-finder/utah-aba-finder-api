# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_10_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "category_fields", force: :cascade do |t|
    t.bigint "provider_category_id", null: false
    t.string "name", null: false
    t.string "field_type", null: false
    t.boolean "required", default: false, null: false
    t.jsonb "options", default: {}
    t.integer "display_order", default: 0, null: false
    t.text "help_text"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["display_order"], name: "index_category_fields_on_display_order"
    t.index ["field_type"], name: "index_category_fields_on_field_type"
    t.index ["is_active"], name: "index_category_fields_on_is_active"
    t.index ["name"], name: "index_category_fields_on_name"
    t.index ["provider_category_id"], name: "index_category_fields_on_provider_category_id"
    t.index ["slug"], name: "index_category_fields_on_slug"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["api_key"], name: "index_clients_on_api_key", unique: true
    t.index ["email"], name: "index_clients_on_email", unique: true
    t.index ["name"], name: "index_clients_on_name", unique: true
    t.index ["reset_password_token"], name: "index_clients_on_reset_password_token", unique: true
  end

  create_table "counties", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "state_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_counties_on_state_id"
  end

  create_table "counties_providers", id: false, force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "county_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["county_id"], name: "index_counties_providers_on_county_id"
    t.index ["provider_id", "county_id"], name: "index_counties_providers_on_provider_id_and_county_id", unique: true
    t.index ["provider_id"], name: "index_counties_providers_on_provider_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "content", null: false
    t.string "template_type", default: "html", null: false
    t.string "description"
    t.string "subject"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "template_type"], name: "index_email_templates_on_name_and_template_type", unique: true
  end

  create_table "insurances", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "name"
    t.string "phone"
    t.string "email"
    t.string "address_1"
    t.string "address_2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "in_home_waitlist", default: "Contact for availability"
    t.text "in_clinic_waitlist", default: "Contact for availability"
    t.index ["in_clinic_waitlist"], name: "index_locations_on_in_clinic_waitlist"
    t.index ["in_home_waitlist"], name: "index_locations_on_in_home_waitlist"
    t.index ["provider_id"], name: "index_locations_on_provider_id"
  end

  create_table "locations_practice_types", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.bigint "practice_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id", "practice_type_id"], name: "index_location_practice_type_on_location_and_practice_type", unique: true
    t.index ["location_id"], name: "index_locations_practice_types_on_location_id"
    t.index ["practice_type_id"], name: "index_locations_practice_types_on_practice_type_id"
  end

  create_table "old_counties", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "counties_served"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_old_counties_on_provider_id"
  end

  create_table "practice_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "provider_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "provider_id", null: false
    t.string "assigned_by", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by"], name: "index_provider_assignments_on_assigned_by"
    t.index ["provider_id"], name: "index_provider_assignments_on_provider_id"
    t.index ["user_id", "provider_id"], name: "index_provider_assignments_on_user_id_and_provider_id", unique: true
    t.index ["user_id"], name: "index_provider_assignments_on_user_id"
  end

  create_table "provider_attributes", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "category_field_id", null: false
    t.text "value"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_field_id"], name: "index_provider_attributes_on_category_field_id"
    t.index ["provider_id", "category_field_id"], name: "index_provider_attributes_on_provider_id_and_category_field_id", unique: true
    t.index ["provider_id"], name: "index_provider_attributes_on_provider_id"
  end

  create_table "provider_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.integer "display_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_provider_categories_on_display_order"
    t.index ["is_active"], name: "index_provider_categories_on_is_active"
    t.index ["slug"], name: "index_provider_categories_on_slug", unique: true
  end

  create_table "provider_claim_requests", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "claimer_email", null: false
    t.string "status", default: "pending", null: false
    t.bigint "reviewed_by_id"
    t.datetime "reviewed_at"
    t.text "admin_notes"
    t.text "rejection_reason"
    t.boolean "is_processed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claimer_email"], name: "index_provider_claim_requests_on_claimer_email"
    t.index ["is_processed"], name: "index_provider_claim_requests_on_is_processed"
    t.index ["provider_id", "status"], name: "index_provider_claim_requests_on_provider_id_and_status"
    t.index ["provider_id"], name: "index_provider_claim_requests_on_provider_id"
    t.index ["status"], name: "index_provider_claim_requests_on_status"
  end

  create_table "provider_insurances", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "insurance_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "accepted"
    t.index ["insurance_id"], name: "index_provider_insurances_on_insurance_id"
    t.index ["provider_id"], name: "index_provider_insurances_on_provider_id"
  end

  create_table "provider_practice_types", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "practice_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["practice_type_id"], name: "index_provider_practice_types_on_practice_type_id"
    t.index ["provider_id", "practice_type_id"], name: "idx_on_provider_id_practice_type_id_1a4497536f", unique: true
    t.index ["provider_id"], name: "index_provider_practice_types_on_provider_id"
  end

  create_table "provider_registrations", force: :cascade do |t|
    t.string "email", null: false
    t.string "provider_name", null: false
    t.string "category", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "submitted_data", default: {}
    t.text "admin_notes"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.text "rejection_reason"
    t.boolean "is_processed", default: false, null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "idempotency_key"
    t.string "service_types", default: [], array: true
    t.index ["category"], name: "index_provider_registrations_on_category"
    t.index ["email"], name: "index_provider_registrations_on_email"
    t.index ["idempotency_key"], name: "index_provider_registrations_on_idempotency_key", unique: true
    t.index ["is_processed"], name: "index_provider_registrations_on_is_processed"
    t.index ["reviewed_by_id"], name: "index_provider_registrations_on_reviewed_by_id"
    t.index ["status"], name: "index_provider_registrations_on_status"
  end

  create_table "provider_service_types", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "provider_category_id", null: false
    t.boolean "is_primary", default: false
    t.jsonb "service_specific_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_category_id"], name: "index_provider_service_types_on_provider_category_id"
    t.index ["provider_id", "is_primary"], name: "index_provider_service_types_on_provider_id_and_is_primary"
    t.index ["provider_id", "provider_category_id"], name: "index_provider_service_types_unique", unique: true
    t.index ["provider_id"], name: "index_provider_service_types_on_provider_id"
  end

  create_table "provider_views", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "fingerprint", null: false
    t.date "view_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "fingerprint", "view_date"], name: "index_provider_views_unique", unique: true
    t.index ["provider_id"], name: "index_provider_views_on_provider_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name"
    t.string "website"
    t.string "email"
    t.string "cost"
    t.float "min_age"
    t.float "max_age"
    t.string "waitlist"
    t.string "at_home_services"
    t.string "in_clinic_services"
    t.string "telehealth_services"
    t.string "spanish_speakers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1, null: false
    t.boolean "in_home_only", default: false, null: false
    t.jsonb "service_delivery", default: {"in_home"=>false, "in_clinic"=>false, "telehealth"=>false}
    t.bigint "user_id"
    t.string "category", default: "aba_therapy"
    t.string "phone"
    t.boolean "is_sponsored", default: false, null: false
    t.datetime "sponsored_until"
    t.integer "sponsorship_tier", default: 0, null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.index ["category"], name: "index_providers_on_category"
    t.index ["is_sponsored"], name: "index_providers_on_is_sponsored"
    t.index ["sponsored_until"], name: "index_providers_on_sponsored_until"
    t.index ["sponsorship_tier"], name: "index_providers_on_sponsorship_tier"
    t.index ["stripe_customer_id"], name: "index_providers_on_stripe_customer_id"
    t.index ["user_id"], name: "index_providers_on_user_id"
  end

  create_table "sponsorships", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_subscription_id"
    t.string "stripe_customer_id"
    t.string "tier", null: false
    t.decimal "amount_paid", precision: 10, scale: 2
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "cancelled_at"
    t.string "status", default: "pending"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_sponsorships_on_provider_id"
    t.index ["status"], name: "index_sponsorships_on_status"
    t.index ["stripe_customer_id"], name: "index_sponsorships_on_stripe_customer_id"
    t.index ["stripe_payment_intent_id"], name: "index_sponsorships_on_stripe_payment_intent_id"
    t.index ["stripe_subscription_id"], name: "index_sponsorships_on_stripe_subscription_id"
    t.index ["tier"], name: "index_sponsorships_on_tier"
  end

  create_table "states", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "provider_id"
    t.string "role"
    t.integer "active_provider_id"
    t.string "first_name"
    t.index ["active_provider_id"], name: "index_users_on_active_provider_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "category_fields", "provider_categories"
  add_foreign_key "counties", "states"
  add_foreign_key "counties_providers", "counties"
  add_foreign_key "counties_providers", "providers"
  add_foreign_key "locations", "providers"
  add_foreign_key "locations_practice_types", "locations"
  add_foreign_key "locations_practice_types", "practice_types"
  add_foreign_key "old_counties", "providers"
  add_foreign_key "provider_assignments", "providers"
  add_foreign_key "provider_assignments", "users"
  add_foreign_key "provider_attributes", "category_fields"
  add_foreign_key "provider_attributes", "providers"
  add_foreign_key "provider_claim_requests", "providers"
  add_foreign_key "provider_claim_requests", "users", column: "reviewed_by_id"
  add_foreign_key "provider_insurances", "insurances"
  add_foreign_key "provider_insurances", "providers"
  add_foreign_key "provider_practice_types", "practice_types"
  add_foreign_key "provider_practice_types", "providers"
  add_foreign_key "provider_registrations", "users", column: "reviewed_by_id"
  add_foreign_key "provider_service_types", "provider_categories"
  add_foreign_key "provider_service_types", "providers"
  add_foreign_key "provider_views", "providers"
  add_foreign_key "providers", "users"
  add_foreign_key "sponsorships", "providers"
  add_foreign_key "users", "providers", column: "active_provider_id"
end
