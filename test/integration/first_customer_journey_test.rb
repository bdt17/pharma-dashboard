require "test_helper"

# The whole first-customer path in one go, the way a new pharmacy meets it:
# sign up -> explore and load sample data -> set up two-factor -> clear the
# samples -> add a vehicle and a shipment -> invite a driver -> the driver
# accepts and records pickup and delivery from a phone -> a Compliance
# Packet is generated. Each step has its own focused tests; this one proves
# they connect. (JS-only parts -- the signature pad and browser GPS -- are
# covered by the system tests; here their results are posted directly.)
class FirstCustomerJourneyTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  SIGNATURE = "data:image/png;base64,#{Base64.strict_encode64(File.binread(Rails.root.join('app/assets/images/sample-signature.png')))}".freeze

  test "a new pharmacy goes from signup to its first Compliance Packet" do
    owner = open_session
    driver = open_session

    # 1. Sign up: straight into the dashboard, unconfirmed, exploring.
    owner.post user_registration_path, params: { user: {
      organization_name: "Main Street Rx", email: "owner@mainstreetrx.test", password: "correct horse battery",
      password_confirmation: "correct horse battery", terms_accepted: "1" } }
    owner.follow_redirect!
    assert_equal 200, owner.response.status
    assert_match "Confirm your email.", owner.response.body
    assert_match "You&rsquo;re exploring.", owner.response.body
    admin = User.find_by!(email: "owner@mainstreetrx.test")
    org = admin.organization

    # test_helper marks two-factor passed for sign-ins with no Warden
    # strategy (Devise's sign-up sign-in is one), which would hide the gate.
    # Come back through the real password login instead, as a returning
    # owner would -- still unconfirmed, inside the 24-hour grace.
    owner.delete destroy_user_session_path
    owner.post user_session_path, params: { user: { email: admin.email, password: "correct horse battery" } }
    owner.get dashboard_path
    assert_equal 200, owner.response.status

    # 2. Try it with sample data, no two-factor yet.
    owner.post sample_data_path
    assert org.reload.sample_data?

    # 3. The first real write asks for two-factor; set it up.
    owner.post vehicles_path, params: { vehicle: { name: "Delivery van" } }
    assert_equal two_factor_setup_url, owner.response.location
    owner.get two_factor_setup_path
    owner.post two_factor_setup_path, params: { otp_code: ROTP::TOTP.new(admin.reload.otp_secret).now }
    assert admin.reload.otp_enabled?

    # 4. Clear the samples, then add real data.
    owner.delete sample_data_path
    assert_not org.reload.sample_data?
    owner.post vehicles_path, params: { vehicle: { name: "Delivery van" } }
    vehicle = org.vehicles.real.find_by!(name: "Delivery van")
    owner.post batches_path, params: { batch: { lot_number: "LOT-2026-0142", name: "Insulin glargine", vehicle_id: vehicle.id } }
    batch = org.batches.real.find_by!(lot_number: "LOT-2026-0142")

    # 5. Invite the driver; they accept from the emailed link.
    perform_enqueued_jobs do
      owner.post team_invitations_path, params: { invitation: { email: "sam@mainstreetrx.test", role: "driver" } }
    end
    token = ActionMailer::Base.deliveries.last.text_part.body.to_s[%r{/invitations/([^\s"<>]+)}, 1]
    assert token, "invitation email has no link"
    driver.post invitation_path(token: token), params: { user: {
      name: "Sam Ruiz", password: "another long password", password_confirmation: "another long password", terms_accepted: "1" } }
    sam = org.users.find_by!(email: "sam@mainstreetrx.test")
    owner.patch batch_path(batch), params: { batch: { lot_number: batch.lot_number, vehicle_id: vehicle.id, driver_id: sam.id } }
    assert_equal sam, batch.reload.driver

    # 6. The driver sees the shipment and records pickup and delivery.
    driver.get deliveries_path
    assert_equal 200, driver.response.status
    assert_match "LOT-2026-0142", driver.response.body
    driver.post batch_custody_logs_path(batch), params: { custody_log: {
      action_type: "pickup", handler_name: "Sam Ruiz", location: "Main Street Rx", temperature_celsius: 4.6,
      latitude: 33.448376, longitude: -112.074036, location_accuracy_m: 9 } }
    perform_enqueued_jobs do
      driver.post batch_custody_logs_path(batch), params: { custody_log: {
        action_type: "delivered", handler_name: "Sam Ruiz", temperature_celsius: 5.1,
        latitude: 33.501234, longitude: -112.101234, location_accuracy_m: 12,
        signature_data: { image: SIGNATURE, signer_name: "Pat Recipient" } } }
    end

    # 7. The record is right, the location is approximate, and the packet exists.
    assert_equal %w[pickup delivered], batch.custody_logs.map(&:action_type)
    delivered = batch.custody_logs.last
    assert_equal sam, delivered.recorded_by
    assert_equal 33.5, delivered.latitude.to_f
    assert_equal "delivered", batch.reload.status
    assert_equal 1, batch.compliance_reports.count, "the delivery should generate the first Compliance Packet"
    assert org.reload.fully_activated?
  end
end
