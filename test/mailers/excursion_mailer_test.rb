require "test_helper"

class ExcursionMailerTest < ActionMailer::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @pharmacist = User.create!(email: "rx@example.com", password: "password123!", organization: @organization, role: "pharmacist")
    User.create!(email: "dispatch@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @vehicle = Vehicle.create!(name: "PHX-001", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-9", name: "Insulin glargine", vehicle: @vehicle, organization: @organization, status: "active")
  end

  test "alert goes to admins and pharmacists only, lot and temperature in the subject" do
    event = ExcursionEvent.create!(batch: @batch, vehicle: @vehicle, started_at: Time.current, trigger_temp: 12.4, peak_temp: 12.4)
    mail = ExcursionMailer.alert(event)

    assert_equal %w[admin@example.com rx@example.com], mail.to.sort
    assert_match "LOT-9", mail.subject
    assert_match "12.4", mail.subject

    body = mail.body.encoded
    assert_match "Insulin glargine", body
    assert_match "/batches/#{@batch.id}/custody_logs", body
  end

  test "resolved names the peak temperature" do
    event = ExcursionEvent.create!(
      batch: @batch, vehicle: @vehicle,
      started_at: 90.minutes.ago, ended_at: Time.current,
      trigger_temp: 12.0, peak_temp: 15.7, readings_count: 8
    )
    mail = ExcursionMailer.resolved(event)

    assert_match "LOT-9", mail.subject
    assert_match "15.7", mail.body.encoded
  end

  test "falls back to the sender address when the org has no admin or pharmacist" do
    @admin.destroy
    @pharmacist.destroy
    event = ExcursionEvent.create!(batch: @batch, started_at: Time.current, trigger_temp: 12.0, peak_temp: 12.0)

    assert_equal [ ExcursionMailer.default[:from] ], ExcursionMailer.alert(event).to
  end
end
