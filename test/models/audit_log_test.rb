require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "auditor@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  test "requires an event" do
    log = AuditLog.new(user: @user)
    assert_not log.valid?
    assert_includes log.errors[:event], "can't be blank"
  end

  test "requires a user" do
    log = AuditLog.new(event: "something_happened")
    assert_not log.valid?
    assert_includes log.errors[:user], "must exist"
  end

  test "batch is optional (not every audited event is batch-scoped)" do
    log = AuditLog.new(event: "user_signed_in", user: @user)
    assert log.valid?
  end

  test ".record! is the one write path" do
    vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: vehicle, organization: @organization)

    log = AuditLog.record!(event: "batch_created", user: @user, batch: batch, ip_address: "127.0.0.1", data: { foo: "bar" })

    assert log.persisted?
    assert_equal "batch_created", log.event
    assert_equal batch, log.batch
    assert_equal "127.0.0.1", log.ip_address
    assert_equal({ "foo" => "bar" }, log.data)
  end
end
