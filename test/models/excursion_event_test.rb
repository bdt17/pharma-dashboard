require "test_helper"

class ExcursionEventTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", vehicle: @vehicle, organization: @organization, status: "active")
  end

  test "ongoing? and the ongoing/resolved scopes track ended_at" do
    open = ExcursionEvent.create!(batch: @batch, started_at: 1.hour.ago, trigger_temp: 12.0, peak_temp: 12.0)
    assert open.ongoing?
    assert_includes ExcursionEvent.ongoing, open
    assert_not_includes ExcursionEvent.resolved, open

    open.update!(ended_at: Time.current)
    assert_not open.reload.ongoing?
    assert_includes ExcursionEvent.resolved, open
  end

  test "direction reports warm above the range and cold below it" do
    assert_equal "warm", ExcursionEvent.new(trigger_temp: 12.0).direction
    assert_equal "cold", ExcursionEvent.new(trigger_temp: 0.5).direction
  end

  test "the partial unique index allows only one open event per batch" do
    ExcursionEvent.create!(batch: @batch, started_at: Time.current, trigger_temp: 12.0, peak_temp: 12.0)

    assert_raises ActiveRecord::RecordNotUnique do
      ExcursionEvent.create!(batch: @batch, started_at: Time.current, trigger_temp: 13.0, peak_temp: 13.0)
    end
  end

  test "a resolved event does not block a new open event for the same batch" do
    ExcursionEvent.create!(batch: @batch, started_at: 2.hours.ago, ended_at: 1.hour.ago, trigger_temp: 12.0, peak_temp: 12.0)

    assert_nothing_raised do
      ExcursionEvent.create!(batch: @batch, started_at: Time.current, trigger_temp: 11.0, peak_temp: 11.0)
    end
  end
end
