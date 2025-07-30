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

ActiveRecord::Schema[7.1].define(version: 2025_07_30_020342) do
  # These are extensions that must be enabled in order to support this database
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

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_clients_on_api_key", unique: true
    t.index ["name"], name: "index_clients_on_name", unique: true
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
    t.boolean "in_home_waitlist", default: false
    t.boolean "in_clinic_waitlist", default: false
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
    t.string "logo"
    t.integer "status", default: 1, null: false
    t.boolean "in_home_only", default: false, null: false
    t.json "service_delivery", default: {"in_home"=>false, "in_clinic"=>false, "telehealth"=>false}
  end

  create_table "states", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "counties", "states"
  add_foreign_key "counties_providers", "counties"
  add_foreign_key "counties_providers", "providers"
  add_foreign_key "locations", "providers"
  add_foreign_key "locations_practice_types", "locations"
  add_foreign_key "locations_practice_types", "practice_types"
  add_foreign_key "old_counties", "providers"
  add_foreign_key "provider_insurances", "insurances"
  add_foreign_key "provider_insurances", "providers"
  add_foreign_key "provider_practice_types", "practice_types"
  add_foreign_key "provider_practice_types", "providers"
end
