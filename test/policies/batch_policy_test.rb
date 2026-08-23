require "test_helper"

class BatchPolicyTest < ActiveSupport::TestCase
  setup do
    @org_a = Organization.create!(name: "Org A")
    @org_b = Organization.create!(name: "Org B")
    @vehicle_a = Vehicle.create!(name: "Truck A", organization: @org_a)
    @driver_a = User.create!(email: "driver-a@example.com", password: "password123!", organization: @org_a, role: "driver")
    @admin_b = User.create!(email: "admin-b@example.com", password: "password123!", organization: @org_b, role: "admin")
    @batch = Batch.create!(
      lot_number: "LOT-1",
      temperature_celsius: 5,
      vehicle: @vehicle_a,
      organization: @org_a,
      driver: @driver_a
    )
  end

  test "a user in another organization cannot view the batch" do
    assert_not BatchPolicy.new(@admin_b, @batch).show?
  end

  test "the assigned driver can always view their own delivery, regardless of organization" do
    out_of_org_driver = User.create!(email: "driver-b@example.com", password: "password123!", organization: @org_b, role: "driver")
    @batch.update!(driver: out_of_org_driver)

    assert BatchPolicy.new(out_of_org_driver, @batch).show?
  end

  test "policy scope only returns batches for the user's own organization" do
    other_vehicle = Vehicle.create!(name: "Truck B", organization: @org_b)
    Batch.create!(lot_number: "LOT-2", temperature_celsius: 5, vehicle: other_vehicle, organization: @org_b)

    scoped = BatchPolicy::Scope.new(@driver_a, Batch.all).resolve
    assert_equal [ @batch ], scoped.to_a
  end

  test "record_custody? allows the assigned driver even though update? does not" do
    assert BatchPolicy.new(@driver_a, @batch).record_custody?
    assert_not BatchPolicy.new(@driver_a, @batch).update?
  end

  test "record_custody? denies a user from a different organization who isn't the assigned driver" do
    assert_not BatchPolicy.new(@admin_b, @batch).record_custody?
  end

  test "record_custody? allows a dispatcher in the same organization" do
    dispatcher_a = User.create!(email: "dispatcher-a@example.com", password: "password123!", organization: @org_a, role: "dispatcher")
    assert BatchPolicy.new(dispatcher_a, @batch).record_custody?
  end

  test "generate_compliance_report? allows admin and dispatcher, denies driver -- even the assigned one" do
    dispatcher_a = User.create!(email: "dispatcher-a@example.com", password: "password123!", organization: @org_a, role: "dispatcher")
    admin_a = User.create!(email: "admin-a@example.com", password: "password123!", organization: @org_a, role: "admin")

    assert BatchPolicy.new(admin_a, @batch).generate_compliance_report?
    assert BatchPolicy.new(dispatcher_a, @batch).generate_compliance_report?
    assert_not BatchPolicy.new(@driver_a, @batch).generate_compliance_report?, "the assigned driver should not be able to issue the billable packet"
  end

  test "generate_compliance_report? denies a user from a different organization" do
    assert_not BatchPolicy.new(@admin_b, @batch).generate_compliance_report?
  end
end
