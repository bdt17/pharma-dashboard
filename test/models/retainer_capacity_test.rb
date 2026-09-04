require "test_helper"

class RetainerCapacityTest < ActiveSupport::TestCase
  def with_active_clients(value)
    original = ENV["COMPLIANCE_OFFICER_ACTIVE_CLIENTS"]
    value.nil? ? ENV.delete("COMPLIANCE_OFFICER_ACTIVE_CLIENTS") : ENV["COMPLIANCE_OFFICER_ACTIVE_CLIENTS"] = value.to_s
    yield
  ensure
    original.nil? ? ENV.delete("COMPLIANCE_OFFICER_ACTIVE_CLIENTS") : ENV["COMPLIANCE_OFFICER_ACTIVE_CLIENTS"] = original
  end

  test "unset defaults to every slot open, not zero clients treated as full" do
    with_active_clients(nil) do
      assert_equal 0, RetainerCapacity.active_clients
      assert_equal RetainerCapacity::TOTAL_SLOTS, RetainerCapacity.slots_available
      assert_not RetainerCapacity.full?
    end
  end

  test "slots_available tracks active_clients" do
    with_active_clients(3) do
      assert_equal 2, RetainerCapacity.slots_available
      assert_not RetainerCapacity.full?
    end
  end

  test "full? once every slot is taken" do
    with_active_clients(RetainerCapacity::TOTAL_SLOTS) do
      assert_equal 0, RetainerCapacity.slots_available
      assert RetainerCapacity.full?
    end
  end

  test "clamps an out-of-range value rather than showing negative slots or overselling" do
    with_active_clients(99) do
      assert_equal RetainerCapacity::TOTAL_SLOTS, RetainerCapacity.active_clients
      assert_equal 0, RetainerCapacity.slots_available
    end

    with_active_clients(-5) do
      assert_equal 0, RetainerCapacity.active_clients
      assert_equal RetainerCapacity::TOTAL_SLOTS, RetainerCapacity.slots_available
    end
  end
end
