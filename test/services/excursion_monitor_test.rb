require "test_helper"

class ExcursionMonitorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", vehicle: @vehicle, organization: @organization, status: "active")
  end

  # Telemetry#after_create_commit runs ExcursionMonitor, so creating a
  # reading is the real entry point being exercised here.
  def ping(temp:, at: Time.current)
    @vehicle.telemetries.create!(lat: 33.4, lng: -112.0, temp: temp, batch: @batch, recorded_at: at)
  end

  test "an out-of-range reading opens one excursion and sends one alert" do
    assert_enqueued_emails 1 do
      ping(temp: 12.0)
    end

    event = ExcursionEvent.ongoing.find_by(batch: @batch)
    assert event
    assert_equal 12.0, event.trigger_temp
    assert_equal 1, event.readings_count
    assert event.alerted_at
  end

  test "further out-of-range readings extend the open event and never re-alert" do
    ping(temp: 12.0)

    assert_no_enqueued_emails do
      ping(temp: 15.0)
      ping(temp: 11.0)
    end

    event = ExcursionEvent.ongoing.find_by(batch: @batch)
    assert_equal 3, event.readings_count
    assert_equal 15.0, event.peak_temp, "peak_temp keeps the most severe reading"
  end

  test "a reading back in range closes the event and sends a resolved notice" do
    ping(temp: 12.0)

    assert_enqueued_emails 1 do
      ping(temp: 5.0)
    end

    assert_nil ExcursionEvent.ongoing.find_by(batch: @batch)
    closed = ExcursionEvent.resolved.find_by(batch: @batch)
    assert closed.ended_at
  end

  test "a second excursion after a resolved one alerts again" do
    ping(temp: 12.0)
    ping(temp: 5.0)

    assert_enqueued_emails 1 do
      ping(temp: 13.0)
    end
    assert_equal 2, ExcursionEvent.where(batch: @batch).count
  end

  test "in-range readings with no open event do nothing" do
    assert_no_enqueued_emails do
      assert_no_difference -> { ExcursionEvent.count } do
        ping(temp: 5.0)
      end
    end
  end

  test "a reading with no batch attached is ignored" do
    assert_no_difference -> { ExcursionEvent.count } do
      @vehicle.telemetries.create!(lat: 33.4, lng: -112.0, temp: 20.0, recorded_at: Time.current)
    end
  end

  test "a reading with no temperature is ignored" do
    assert_no_difference -> { ExcursionEvent.count } do
      @vehicle.telemetries.create!(lat: 33.4, lng: -112.0, batch: @batch, recorded_at: Time.current)
    end
  end
end
