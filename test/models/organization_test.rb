require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "requires a name" do
    org = Organization.new
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "cannot be destroyed while it still has users" do
    org = Organization.create!(name: "Acme Pharma")
    User.create!(email: "keeper@example.com", password: "password123!", organization: org, role: "admin")

    assert_not org.destroy
    assert_includes org.errors[:base].join, "Cannot delete record"
  end
end
