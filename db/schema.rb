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

ActiveRecord::Schema[8.1].define(version: 2026_01_17_083308) do
  create_table "audit_logs", force: :cascade do |t|
    t.integer "batch_id"
    t.datetime "created_at", null: false
    t.json "data"
    t.string "event", null: false
    t.string "ip_address", limit: 45
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["batch_id"], name: "index_audit_logs_on_batch_id"
    t.index ["event"], name: "index_audit_logs_on_event"
    t.index ["ip_address"], name: "index_audit_logs_on_ip_address"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expiry"
    t.string "lot"
    t.string "status"
    t.float "temperature_celsius"
    t.datetime "updated_at", null: false
    t.index ["lot"], name: "index_batches_on_lot", unique: true
  end

  create_table "location_points", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "recorded_at"
    t.float "speed"
    t.datetime "updated_at", null: false
    t.integer "vehicle_id", null: false
    t.index ["vehicle_id"], name: "index_location_points_on_vehicle_id"
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

  create_table "vehicles", force: :cascade do |t|
    t.integer "batch_id"
    t.datetime "created_at", null: false
    t.float "heading"
    t.float "lat"
    t.float "lng"
    t.float "speed"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "audit_logs", "batches"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "location_points", "vehicles"
end
