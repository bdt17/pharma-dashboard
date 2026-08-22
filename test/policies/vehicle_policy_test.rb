require "test_helper"

class VehiclePolicyTest < ActiveSupport::TestCase
  setup do
    @org_a = Organization.create!(name: "Org A")
    @org_b = Organization.create!(name: "Org B")
    @admin_a = User.create!(email: "admin-a@example.com", password: "password123!", organization: @org_a, role: "admin")
    @admin_b = User.create!(email: "admin-b@example.com", password: "password123!", organization: @org_b, role: "admin")
    @vehicle_a = Vehicle.create!(name: "Truck A", organization: @org_a)
  end

  test "a user cannot view another organization's vehicle" do
    assert_not VehiclePolicy.new(@admin_b, @vehicle_a).show?
  end

  test "a user can view their own organization's vehicle" do
    assert VehiclePolicy.new(@admin_a, @vehicle_a).show?
  end

  test "policy scope only returns vehicles for the user's own organization" do
    Vehicle.create!(name: "Truck B", organization: @org_b)

    scoped = VehiclePolicy::Scope.new(@admin_a, Vehicle.all).resolve
    assert_equal [ @vehicle_a ], scoped.to_a
  end

  test "a driver cannot create or destroy vehicles" do
    driver = User.create!(email: "driver-a@example.com", password: "password123!", organization: @org_a, role: "driver")
    assert_not VehiclePolicy.new(driver, Vehicle.new).create?
    assert_not VehiclePolicy.new(driver, @vehicle_a).destroy?
  end
end
