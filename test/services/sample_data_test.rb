require "test_helper"

class SampleDataTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @org = Organization.create!(name: "Main Street Rx")
    @admin = User.create!(email: "owner@example.com", password: "password123!", organization: @org, role: "admin")
  end

  test "loads flagged sample shipments with custody, readings, and one excursion" do
    assert SampleData.load!(@org, user: @admin)

    assert_equal 4, @org.batches.samples.count
    assert_equal 2, @org.vehicles.samples.count
    assert_equal 0, @org.batches.real.count
    assert @org.batches.all? { |b| b.lot_number.start_with?(SampleData::LOT_PREFIX) }
    assert_equal 1, ExcursionEvent.where(batch: @org.batches).count
    delivered = CustodyLog.joins(:batch).where(batches: { organization_id: @org.id }, action_type: "delivered")
    assert_equal 2, delivered.count
    assert delivered.all?(&:signed?)
    assert Telemetry.where(batch: @org.batches).exists?
    assert @org.sample_data?
  end

  test "sends no alerts, webhooks, or packets" do
    assert_no_enqueued_emails do
      assert_no_difference -> { ComplianceReport.count } do
        assert_no_difference -> { WebhookDelivery.count } do
          SampleData.load!(@org, user: @admin)
        end
      end
    end
  end

  test "does not count toward the getting-started checklist" do
    SampleData.load!(@org, user: @admin)
    assert_not @org.added_a_vehicle?
    assert_not @org.logged_a_batch?
    assert_not @org.fully_activated?
  end

  test "is only offered before the first real shipment, and only once" do
    assert SampleData.available?(@org)
    SampleData.load!(@org, user: @admin)
    assert_not SampleData.available?(@org)
    assert_not SampleData.load!(@org, user: @admin)

    other = Organization.create!(name: "Busy Rx")
    Batch.create!(lot_number: "LOT-1", vehicle: Vehicle.create!(name: "Van", organization: other), organization: other)
    assert_not SampleData.available?(other)
  end

  test "clear removes every sample record and nothing real" do
    SampleData.load!(@org, user: @admin)
    real_vehicle = Vehicle.create!(name: "Our van", organization: @org)
    real_batch = Batch.create!(lot_number: "LOT-REAL", vehicle: real_vehicle, organization: @org)
    CustodyLog.create!(batch: real_batch, action_type: "pickup", handler_name: "Ana", location: "Store")

    SampleData.clear!(@org)

    assert_not @org.sample_data?
    assert_equal [ real_batch ], @org.batches.to_a
    assert_equal [ real_vehicle ], @org.vehicles.to_a
    assert_equal 1, CustodyLog.where(batch: real_batch).count
    assert_equal 0, ExcursionEvent.count
    assert_equal 0, Telemetry.where.not(batch_id: real_batch.id).count
  end

  test "clear leaves other organizations alone" do
    other = Organization.create!(name: "Other Rx")
    SampleData.load!(other)
    SampleData.load!(@org, user: @admin)

    SampleData.clear!(@org)

    assert other.sample_data?
    assert_equal 4, other.batches.samples.count
  end

  test "a sample chain-of-custody PDF says it is a sample" do
    SampleData.load!(@org, user: @admin)
    pdf = PdfChainOfCustodyGenerator.new(@org.batches.samples.first).generate
    text = PDF::Reader.new(StringIO.new(pdf)).pages.map(&:text).join(" ")
    assert_includes text, "SAMPLE DATA - not a real shipment or record"
  end

  test "the delivery packet job never issues a packet for a sample delivery" do
    SampleData.load!(@org, user: @admin)
    log = CustodyLog.joins(:batch).where(batches: { organization_id: @org.id }, action_type: "delivered").first

    assert_no_difference -> { ComplianceReport.count } do
      GenerateDeliveryPacketJob.perform_now(log.id, @admin.id)
    end
  end
end
