require "test_helper"
require "pdf/reader"
require "stringio"

class PdfChainOfCustodyGeneratorTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @user = User.create!(email: "handler@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @batch = Batch.create!(lot_number: "LOT-42", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
  end

  def extracted_text(batch)
    bytes = PdfChainOfCustodyGenerator.new(batch).generate
    PDF::Reader.new(StringIO.new(bytes)).pages.map(&:text).join(" ")
  end

  test "includes the batch's real lot number and organization, not placeholder text" do
    text = extracted_text(@batch)

    assert_includes text, "LOT-42"
    assert_includes text, "Acme Pharma"
    refute_includes text, "LOT-PHARMA-20260207", "should not contain the old hardcoded placeholder batch id"
  end

  test "shows COMPLIANT for a batch within the 2-8°C range" do
    text = extracted_text(@batch)
    assert_includes text, "COMPLIANT"
  end

  test "shows NON-COMPLIANT for a batch outside the 2-8°C range" do
    @batch.update!(temperature_celsius: 15)
    text = extracted_text(@batch)
    assert_includes text, "NON-COMPLIANT"
  end

  test "includes real custody log entries, not the hardcoded 'Position updated' placeholder" do
    CustodyLog.create!(batch: @batch, action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ")

    text = extracted_text(@batch)
    assert_includes text, "Jane Doe"
    assert_includes text, "Phoenix, AZ"
    refute_includes text, "Position updated"
  end

  test "includes real audit log entries" do
    AuditLog.record!(event: "chain_of_custody_pdf_generated", user: @user, batch: @batch)

    text = extracted_text(@batch)
    assert_includes text, @user.email
    assert_includes text, "chain_of_custody_pdf_generated"
  end

  test "says so when there is no custody or audit history yet, rather than inventing any" do
    text = extracted_text(@batch)
    assert_includes text, "No custody events recorded"
    assert_includes text, "No audit events recorded"
  end

  test "says so when there is no temperature-monitoring data yet, rather than inventing any" do
    text = extracted_text(@batch)
    assert_includes text, "No temperature-monitoring data recorded"
  end

  test "lists real temperature excursions with their location, not just the count" do
    @batch.telemetries.create!(vehicle: @vehicle, lat: 33.4484, lng: -112.0740, temp: 5.0, recorded_at: 1.hour.ago)
    @batch.telemetries.create!(vehicle: @vehicle, lat: 34.0522, lng: -118.2437, temp: 12.5, recorded_at: 30.minutes.ago)

    text = extracted_text(@batch)
    assert_includes text, "2 readings"
    assert_includes text, "1 outside"
    assert_includes text, "12.5"
    assert_includes text, "34.0522"
  end

  test "does not list an excursion table when every reading is within range" do
    @batch.telemetries.create!(vehicle: @vehicle, lat: 33.4484, lng: -112.0740, temp: 5.0)

    text = extracted_text(@batch)
    assert_includes text, "0 outside"
    refute_includes text, "Location", "no excursion table should render when there's nothing to list"
  end
end
