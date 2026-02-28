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

ActiveRecord::Schema[8.1].define(version: 2026_02_26_232605) do
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
    t.index ["batch_id"], name: "index_audit_logs_on_batch_id"
    t.index ["event"], name: "index_audit_logs_on_event"
    t.index ["ip_address"], name: "index_audit_logs_on_ip_address"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.text "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "batches", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "batch_number"
    t.datetime "created_at", null: false
    t.date "expiry"
    t.string "lot"
    t.string "lot_number", default: "LOT-UNASSIGNED", null: false
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "status"
    t.float "temperature_celsius"
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["lot"], name: "index_batches_on_lot", unique: true
    t.index ["lot_number"], name: "index_batches_on_lot_number", unique: true
    t.index ["organization_id"], name: "index_batches_on_organization_id"
    t.index ["vehicle_id"], name: "index_batches_on_vehicle_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_drivers_on_user_id"
  end

  create_table "gps_logs", id: :serial, force: :cascade do |t|
    t.string "imei", limit: 15
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "speed"
    t.decimal "temperature"
    t.datetime "timestamp", precision: nil, default: -> { "now()" }
  end

  create_table "knowledge_bases", force: :cascade do |t|
    t.string "category"
    t.text "client_instructions"
    t.text "commands"
    t.datetime "created_at", null: false
    t.text "steps"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "location_points", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "recorded_at"
    t.float "speed"
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id"
  end

  create_table "locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "heading"
    t.float "lat"
    t.float "lng"
    t.float "speed"
    t.datetime "timestamp"
    t.datetime "updated_at", null: false
    t.integer "vehicle_id"
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

  create_table "pharmacists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_pharmacists_on_email", unique: true
    t.index ["reset_password_token"], name: "index_pharmacists_on_reset_password_token", unique: true
  end

  create_table "revenues", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.date "date"
    t.datetime "updated_at", null: false
  end

  create_table "shipments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "delivery_location"
    t.integer "driver_id"
    t.string "pickup_location"
    t.integer "status"
    t.text "temperature_logs"
    t.string "tracking_number"
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
    t.bigint "batch_id", null: false
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

  create_table "tickets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "client"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "vehicles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "identifier"
    t.float "lat"
    t.float "latitude"
    t.float "lng"
    t.float "longitude"
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "plate"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_vehicles_on_organization_id"
  end

  add_foreign_key "audit_logs", "batches"
  add_foreign_key "batches", "organizations"
  add_foreign_key "batches", "vehicles"
  add_foreign_key "drivers", "users"
  add_foreign_key "orders", "patients"
  add_foreign_key "subscriptions", "organizations"
  add_foreign_key "telemetries", "batches"
  add_foreign_key "telemetries", "vehicles"
  add_foreign_key "vehicles", "organizations"
end
