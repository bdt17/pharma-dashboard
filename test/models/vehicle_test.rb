require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  test "generates an api_token automatically" do
    vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    assert vehicle.api_token.present?
  end

  test "does not overwrite an explicitly assigned api_token" do
    vehicle = Vehicle.create!(name: "Truck 1", organization: @organization, api_token: "explicit-token")
    assert_equal "explicit-token", vehicle.api_token
  end

  test "imei must be unique when present" do
    Vehicle.create!(name: "Truck 1", organization: @organization, imei: "123456789012345")
    dupe = Vehicle.new(name: "Truck 2", organization: @organization, imei: "123456789012345")

    assert_not dupe.valid?
    assert_includes dupe.errors[:imei], "has already been taken"
  end

  test "multiple vehicles without an imei are both valid (uniqueness allows nil)" do
    Vehicle.create!(name: "Truck 1", organization: @organization)
    other = Vehicle.new(name: "Truck 2", organization: @organization)

    assert other.valid?
  end

  test "api_token_matches? uses a constant-time comparison and rejects blanks" do
    vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)

    assert vehicle.api_token_matches?(vehicle.api_token)
    assert_not vehicle.api_token_matches?("wrong-token")
    assert_not vehicle.api_token_matches?(nil)
    assert_not vehicle.api_token_matches?("")
  end
end
