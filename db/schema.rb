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

ActiveRecord::Schema[8.1].define(version: 2026_08_23_040000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message"
    t.boolean "resolved"
    t.datetime "updated_at", null: false
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.json "data"
    t.string "event", null: false
    t.string "ip_address", limit: 45
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["batch_id"], name: "index_audit_logs_on_batch_id"
    t.index ["event"], name: "index_audit_logs_on_event"
    t.index ["ip_address"], name: "index_audit_logs_on_ip_address"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "batch_number"
    t.datetime "created_at", null: false
    t.bigint "driver_id"
    t.date "expiry"
    t.string "lot"
    t.string "lot_number", default: "LOT-UNASSIGNED", null: false
    t.string "name"
    t.bigint "organization_id"
    t.string "status"
    t.float "temperature_celsius"
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["driver_id"], name: "index_batches_on_driver_id"
    t.index ["lot"], name: "index_batches_on_lot", unique: true
    t.index ["lot_number"], name: "index_batches_on_lot_number", unique: true
    t.index ["vehicle_id"], name: "index_batches_on_vehicle_id"
  end

  create_table "compliance_reports", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.bigint "generated_by_id", null: false
    t.bigint "organization_id", null: false
    t.binary "pdf_data", null: false
    t.string "previous_hash"
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.index ["batch_id", "version"], name: "index_compliance_reports_on_batch_id_and_version", unique: true
    t.index ["batch_id"], name: "index_compliance_reports_on_batch_id"
    t.index ["generated_by_id"], name: "index_compliance_reports_on_generated_by_id"
    t.index ["organization_id"], name: "index_compliance_reports_on_organization_id"
  end

  create_table "custody_logs", force: :cascade do |t|
    t.string "action_type"
    t.bigint "batch_id", null: false
    t.text "condition_notes"
    t.datetime "created_at", null: false
    t.string "handler_name"
    t.string "location"
    t.jsonb "signature_data"
    t.datetime "timestamp"
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_custody_logs_on_batch_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "patient_id", null: false
    t.bigint "pharmacy_id"
    t.string "status"
    t.string "tracking_id"
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_orders_on_patient_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "plan"
    t.string "status"
    t.string "stripe_customer_id"
    t.string "subdomain"
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "patients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_patients_on_email", unique: true
    t.index ["reset_password_token"], name: "index_patients_on_reset_password_token", unique: true
  end

  create_table "revenues", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.date "date"
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.bigint "organization_id", null: false
    t.decimal "plan_amount"
    t.string "status"
    t.string "stripe_subscription_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_subscriptions_on_organization_id"
  end

  create_table "telemetries", force: :cascade do |t|
    t.bigint "batch_id"
    t.float "battery"
    t.datetime "created_at", null: false
    t.float "lat"
    t.float "lng"
    t.datetime "recorded_at"
    t.integer "signal_strength"
    t.float "speed"
    t.float "temp"
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["batch_id"], name: "index_telemetries_on_batch_id"
    t.index ["vehicle_id"], name: "index_telemetries_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "name"
    t.bigint "organization_id"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.integer "heading"
    t.string "identifier"
    t.string "imei"
    t.datetime "last_ping_at"
    t.float "latitude"
    t.float "longitude"
    t.string "name"
    t.bigint "organization_id"
    t.string "plate"
    t.float "speed"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_vehicles_on_api_token", unique: true
    t.index ["imei"], name: "index_vehicles_on_imei", unique: true
  end

  add_foreign_key "audit_logs", "batches"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "batches", "organizations"
  add_foreign_key "batches", "users", column: "driver_id"
  add_foreign_key "batches", "vehicles"
  add_foreign_key "compliance_reports", "batches"
  add_foreign_key "compliance_reports", "organizations"
  add_foreign_key "compliance_reports", "users", column: "generated_by_id"
  add_foreign_key "custody_logs", "batches"
  add_foreign_key "orders", "patients"
  add_foreign_key "subscriptions", "organizations"
  add_foreign_key "telemetries", "batches"
  add_foreign_key "telemetries", "vehicles"
  add_foreign_key "users", "organizations"
  add_foreign_key "vehicles", "organizations"
end
