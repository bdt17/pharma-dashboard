require "test_helper"

class DemoDataTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Demo Pharma Transport", plan: "enterprise", status: "active")
  end

  test "populate! builds vehicles, batches, custody chains and telemetry" do
    DemoData.populate!(@org)

    assert_equal DemoData::VEHICLES.size, @org.vehicles.count
    assert_equal 14, @org.batches.count
    assert_equal 2, @org.batches.non_compliant.count
    assert_equal 2, @org.batches.where(temperature_celsius: nil).count

    custody = CustodyLog.joins(:batch).where(batches: { organization_id: @org.id })
    assert custody.count >= 42
    assert custody.where(action_type: "delivered").exists?

    telemetry = Telemetry.joins(:batch).where(batches: { organization_id: @org.id })
    assert telemetry.any?
  end

  test "the active vehicles look freshly pinged and the idle one stale" do
    DemoData.populate!(@org)

    online = @org.vehicles.where("last_ping_at > ?", 15.minutes.ago)
    assert_equal 3, online.count
    assert @org.vehicles.find_by(name: "MSA-001").last_ping_at.nil?
  end

  test "reset! is idempotent -- rebuilds to the same shape without piling up" do
    DemoData.populate!(@org)
    DemoData.reset!(@org)
    DemoData.reset!(@org)

    assert_equal DemoData::VEHICLES.size, @org.vehicles.count
    assert_equal 14, @org.batches.count
  end
end
