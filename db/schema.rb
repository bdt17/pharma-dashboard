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

ActiveRecord::Schema[8.1].define(version: 2026_09_04_000011) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alert_recipients", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.bigint "organization_id", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "phone"], name: "index_alert_recipients_on_organization_id_and_phone", unique: true
    t.index ["organization_id"], name: "index_alert_recipients_on_organization_id"
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

  create_table "call_requests", force: :cascade do |t|
    t.text "context"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "handled_at"
    t.text "message"
    t.string "name", null: false
    t.string "pharmacy_name"
    t.string "phone"
    t.string "topic", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_call_requests_on_created_at"
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

  create_table "dscsa_assessments", force: :cascade do |t|
    t.jsonb "answers", default: {}, null: false
    t.string "band", default: "unknown", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "pharmacy_name"
    t.integer "score", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_dscsa_assessments_on_token", unique: true
  end

  create_table "email_suppressions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_email_suppressions_on_email", unique: true
  end

  create_table "excursion_events", force: :cascade do |t|
    t.datetime "alerted_at"
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.float "peak_temp", null: false
    t.integer "readings_count", default: 1, null: false
    t.datetime "started_at", null: false
    t.float "trigger_temp", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id"
    t.index ["batch_id"], name: "index_excursion_events_on_batch_id"
    t.index ["batch_id"], name: "index_excursion_events_one_open_per_batch", unique: true, where: "(ended_at IS NULL)"
    t.index ["vehicle_id"], name: "index_excursion_events_on_vehicle_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "card_expiry_notified_for"
    t.datetime "created_at", null: false
    t.string "name"
    t.boolean "overage_billing_enabled", default: false, null: false
    t.string "plan"
    t.string "referral_code"
    t.boolean "sms_quiet_hours_enabled", default: false, null: false
    t.string "status"
    t.string "stripe_customer_id"
    t.string "subdomain"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.string "verification_token"
    t.index ["referral_code"], name: "index_organizations_on_referral_code", unique: true
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
    t.index ["verification_token"], name: "index_organizations_on_verification_token", unique: true
  end

  create_table "packet_overages", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.bigint "compliance_report_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "usd", null: false
    t.bigint "organization_id", null: false
    t.string "stripe_invoice_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["compliance_report_id"], name: "index_packet_overages_on_compliance_report_id", unique: true
    t.index ["organization_id"], name: "index_packet_overages_on_organization_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "referred_organization_id", null: false
    t.bigint "referrer_organization_id", null: false
    t.datetime "rewarded_at"
    t.datetime "updated_at", null: false
    t.index ["referred_organization_id"], name: "index_referrals_on_referred_organization_id", unique: true
    t.index ["referrer_organization_id"], name: "index_referrals_on_referrer_organization_id"
  end

  create_table "report_credits", force: :cascade do |t|
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.integer "sequence", default: 1, null: false
    t.string "stripe_checkout_session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_report_credits_on_organization_id"
    t.index ["stripe_checkout_session_id", "sequence"], name: "index_report_credits_on_session_id_and_sequence", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.integer "completed_jobs", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "enqueued_at"
    t.datetime "failed_at"
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "finished_at"
    t.text "metadata"
    t.text "on_failure"
    t.text "on_finish"
    t.text "on_success"
    t.integer "total_jobs", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.bigint "batch_id"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.integer "dunning_email_count", default: 0, null: false
    t.datetime "last_dunning_email_at"
    t.bigint "organization_id", null: false
    t.decimal "plan_amount"
    t.string "status"
    t.string "stripe_subscription_id"
    t.string "tier"
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
    t.text "otp_backup_codes"
    t.integer "otp_consumed_timestep"
    t.boolean "otp_enabled", default: false, null: false
    t.datetime "otp_enabled_at"
    t.string "otp_secret"
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
    t.index ["imei"], name: "index_vehicles_on_imei", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.string "error"
    t.string "event", null: false
    t.string "event_id", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "replayed_from_id"
    t.integer "response_status"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "webhook_endpoint_id", null: false
    t.index ["event_id"], name: "index_webhook_deliveries_on_event_id"
    t.index ["webhook_endpoint_id", "created_at"], name: "index_webhook_deliveries_on_webhook_endpoint_id_and_created_at"
    t.index ["webhook_endpoint_id"], name: "index_webhook_deliveries_on_webhook_endpoint_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "consecutive_failures", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "last_error"
    t.datetime "last_failure_at"
    t.datetime "last_success_at"
    t.bigint "organization_id", null: false
    t.string "signing_secret", null: false
    t.string "subscribed_events", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["organization_id", "url"], name: "index_webhook_endpoints_on_organization_id_and_url", unique: true
    t.index ["organization_id"], name: "index_webhook_endpoints_on_organization_id"
  end

  add_foreign_key "alert_recipients", "organizations"
  add_foreign_key "audit_logs", "batches"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "batches", "organizations"
  add_foreign_key "batches", "users", column: "driver_id"
  add_foreign_key "batches", "vehicles"
  add_foreign_key "compliance_reports", "batches"
  add_foreign_key "compliance_reports", "organizations"
  add_foreign_key "compliance_reports", "users", column: "generated_by_id"
  add_foreign_key "custody_logs", "batches"
  add_foreign_key "excursion_events", "batches"
  add_foreign_key "excursion_events", "vehicles"
  add_foreign_key "packet_overages", "compliance_reports"
  add_foreign_key "packet_overages", "organizations"
  add_foreign_key "referrals", "organizations", column: "referred_organization_id"
  add_foreign_key "referrals", "organizations", column: "referrer_organization_id"
  add_foreign_key "report_credits", "organizations"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "subscriptions", "organizations"
  add_foreign_key "telemetries", "batches"
  add_foreign_key "telemetries", "vehicles"
  add_foreign_key "users", "organizations"
  add_foreign_key "vehicles", "organizations"
  add_foreign_key "webhook_deliveries", "webhook_endpoints"
  add_foreign_key "webhook_endpoints", "organizations"
end
