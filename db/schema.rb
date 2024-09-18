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

ActiveRecord::Schema[7.1].define(version: 2024_09_18_030150) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_clients_on_api_key", unique: true
    t.index ["name"], name: "index_clients_on_name", unique: true
  end

  create_table "counties", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "counties_served"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_counties_on_provider_id"
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
    t.index ["provider_id"], name: "index_locations_on_provider_id"
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
  end

  add_foreign_key "counties", "providers"
  add_foreign_key "locations", "providers"
  add_foreign_key "provider_insurances", "insurances"
  add_foreign_key "provider_insurances", "providers"
end
