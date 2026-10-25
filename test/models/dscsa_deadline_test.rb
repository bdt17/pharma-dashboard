require "test_helper"

class DscsaDeadlineTest < ActiveSupport::TestCase
  test "the deadline day itself has not passed; the next day has" do
    assert_not DscsaDeadline.passed?(on: Date.new(2026, 11, 27))
    assert DscsaDeadline.passed?(on: Date.new(2026, 11, 28))
  end

  test "flips at midnight US Eastern, not UTC" do
    # 03:00 UTC on Nov 28 is still Nov 27 in New York.
    travel_to Time.utc(2026, 11, 28, 3, 0) { assert_not DscsaDeadline.passed? }
    travel_to Time.utc(2026, 11, 28, 6, 0) { assert DscsaDeadline.passed? }
  end

  test "days_left counts down to zero and never goes negative" do
    assert_equal 33, DscsaDeadline.days_left(on: Date.new(2026, 10, 25))
    assert_equal 0, DscsaDeadline.days_left(on: Date.new(2026, 11, 27))
    assert_equal 0, DscsaDeadline.days_left(on: Date.new(2026, 12, 15))
  end
end
