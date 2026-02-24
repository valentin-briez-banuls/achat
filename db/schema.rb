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

ActiveRecord::Schema[8.1].define(version: 2026_02_24_103900) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "financial_profiles", force: :cascade do |t|
    t.decimal "borrowing_capacity", precision: 12, scale: 2
    t.integer "contract_type_person_1", default: 0
    t.integer "contract_type_person_2", default: 0
    t.datetime "created_at", null: false
    t.decimal "debt_ratio", precision: 5, scale: 2
    t.integer "desired_duration_years", default: 25
    t.decimal "fiscal_reference_income", precision: 12, scale: 2, default: "0.0"
    t.bigint "household_id", null: false
    t.integer "household_size", default: 2
    t.decimal "max_monthly_payment", precision: 10, scale: 2
    t.decimal "monthly_charges", precision: 10, scale: 2, default: "0.0"
    t.decimal "other_income", precision: 10, scale: 2, default: "0.0"
    t.decimal "personal_contribution", precision: 12, scale: 2, default: "0.0"
    t.decimal "proposed_rate", precision: 5, scale: 3
    t.string "ptz_zone"
    t.decimal "remaining_savings", precision: 12, scale: 2, default: "0.0"
    t.decimal "remaining_to_live", precision: 10, scale: 2
    t.decimal "salary_person_1", precision: 10, scale: 2, default: "0.0"
    t.decimal "salary_person_2", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_financial_profiles_on_household_id", unique: true
  end

  create_table "households", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "invitation_token"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["invitation_token"], name: "index_households_on_invitation_token", unique: true
  end

  create_table "offers", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.text "conditions"
    t.decimal "counter_offer_amount", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.text "notes"
    t.date "offered_on", null: false
    t.bigint "property_id", null: false
    t.date "response_deadline"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_offers_on_property_id"
    t.index ["status"], name: "index_offers_on_status"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address"
    t.decimal "agency_fees", precision: 10, scale: 2, default: "0.0"
    t.boolean "agency_fees_included", default: true
    t.integer "bedrooms"
    t.string "city", null: false
    t.integer "condition", default: 0
    t.decimal "copro_charges_monthly", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.string "energy_class"
    t.decimal "estimated_works", precision: 10, scale: 2, default: "0.0"
    t.integer "floor"
    t.string "ges_class"
    t.boolean "has_outdoor", default: false
    t.boolean "has_parking", default: false
    t.bigint "household_id", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.string "listing_url"
    t.decimal "longitude", precision: 10, scale: 7
    t.decimal "notary_fees_estimate", precision: 10, scale: 2
    t.text "personal_notes"
    t.string "postal_code", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.decimal "property_tax_yearly", precision: 8, scale: 2, default: "0.0"
    t.integer "property_type", default: 0
    t.integer "rooms"
    t.integer "score_brightness"
    t.integer "score_neighborhood"
    t.integer "score_orientation"
    t.integer "score_quietness"
    t.integer "score_renovation"
    t.integer "score_view"
    t.integer "status", default: 0
    t.decimal "surface", precision: 8, scale: 2, null: false
    t.string "title", null: false
    t.integer "total_floors"
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_properties_on_city"
    t.index ["household_id"], name: "index_properties_on_household_id"
    t.index ["postal_code"], name: "index_properties_on_postal_code"
    t.index ["status"], name: "index_properties_on_status"
  end

  create_table "property_criteria", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "geographic_zone"
    t.bigint "household_id", null: false
    t.decimal "max_budget", precision: 12, scale: 2
    t.decimal "max_work_distance_km", precision: 6, scale: 1
    t.integer "min_bedrooms", default: 1
    t.string "min_energy_class"
    t.decimal "min_surface", precision: 8, scale: 2
    t.boolean "outdoor_required", default: false
    t.boolean "parking_required", default: false
    t.integer "property_condition", default: 0
    t.datetime "updated_at", null: false
    t.integer "weight_brightness", default: 5
    t.integer "weight_neighborhood", default: 5
    t.integer "weight_orientation", default: 5
    t.integer "weight_quietness", default: 5
    t.integer "weight_renovation", default: 5
    t.integer "weight_view", default: 5
    t.index ["household_id"], name: "index_property_criteria_on_household_id", unique: true
  end

  create_table "property_scores", force: :cascade do |t|
    t.integer "bedrooms_score", default: 0
    t.integer "brightness_score", default: 0
    t.integer "budget_score", default: 0
    t.integer "compatibility"
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}
    t.integer "energy_score", default: 0
    t.integer "location_score", default: 0
    t.integer "neighborhood_score", default: 0
    t.integer "orientation_score", default: 0
    t.integer "outdoor_score", default: 0
    t.integer "parking_score", default: 0
    t.bigint "property_id", null: false
    t.integer "quietness_score", default: 0
    t.integer "renovation_score", default: 0
    t.integer "surface_score", default: 0
    t.integer "total_score", default: 0
    t.datetime "updated_at", null: false
    t.integer "view_score", default: 0
    t.index ["property_id"], name: "index_property_scores_on_property_id", unique: true
    t.index ["total_score"], name: "index_property_scores_on_total_score"
  end

  create_table "simulations", force: :cascade do |t|
    t.decimal "additional_works", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.decimal "debt_ratio", precision: 5, scale: 2
    t.integer "loan_duration_years"
    t.decimal "loan_rate", precision: 5, scale: 3
    t.decimal "main_loan_amount", precision: 12, scale: 2
    t.decimal "monthly_payment_main", precision: 10, scale: 2
    t.decimal "monthly_payment_ptz", precision: 10, scale: 2, default: "0.0"
    t.string "name"
    t.decimal "negotiated_price", precision: 12, scale: 2
    t.decimal "notary_fees", precision: 10, scale: 2
    t.decimal "personal_contribution", precision: 12, scale: 2
    t.decimal "price_negotiation_percent", precision: 5, scale: 2, default: "0.0"
    t.bigint "property_id", null: false
    t.decimal "ptz_amount", precision: 12, scale: 2, default: "0.0"
    t.boolean "ptz_eligible", default: false
    t.decimal "real_monthly_effort", precision: 10, scale: 2
    t.integer "scenario", default: 0
    t.decimal "total_credit_cost", precision: 12, scale: 2
    t.decimal "total_monthly_payment", precision: 10, scale: 2
    t.decimal "total_project_cost", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_simulations_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.bigint "household_id"
    t.string "last_name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["household_id"], name: "index_users_on_household_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.text "cons"
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "property_id", null: false
    t.text "pros"
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "verdict"
    t.index ["property_id"], name: "index_visits_on_property_id"
    t.index ["scheduled_at"], name: "index_visits_on_scheduled_at"
    t.index ["user_id"], name: "index_visits_on_user_id"
  end

  add_foreign_key "financial_profiles", "households"
  add_foreign_key "offers", "properties"
  add_foreign_key "properties", "households"
  add_foreign_key "property_criteria", "households"
  add_foreign_key "property_scores", "properties"
  add_foreign_key "simulations", "properties"
  add_foreign_key "users", "households"
  add_foreign_key "visits", "properties"
  add_foreign_key "visits", "users"
end
