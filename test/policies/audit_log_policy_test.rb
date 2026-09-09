require "test_helper"

class AuditLogPolicyTest < ActiveSupport::TestCase
  setup do
    @org_a = Organization.create!(name: "Org A")
    @org_b = Organization.create!(name: "Org B")
    @admin_a = User.create!(email: "admin-a@example.com", password: "password123!", organization: @org_a, role: "admin")
    @driver_a = User.create!(email: "driver-a@example.com", password: "password123!", organization: @org_a, role: "driver")
  end

  test "index? is open to any org member -- read-only, nothing to mutate" do
    assert AuditLogPolicy.new(@admin_a, AuditLog).index?
    assert AuditLogPolicy.new(@driver_a, AuditLog).index?
  end

  test "scope only returns audit logs belonging to the user's own organization" do
    admin_b = User.create!(email: "admin-b@example.com", password: "password123!", organization: @org_b, role: "admin")
    mine = AuditLog.record!(event: "mine", user: @admin_a)
    AuditLog.record!(event: "theirs", user: admin_b)

    scoped = AuditLogPolicy::Scope.new(@admin_a, AuditLog.all).resolve
    assert_equal [ mine ], scoped.to_a
  end
end
