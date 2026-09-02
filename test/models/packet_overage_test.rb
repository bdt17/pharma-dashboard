require "test_helper"

class PacketOverageTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  def report
    ComplianceReport.create_next_version!(
      batch: @batch, generated_by: @admin, content_hash: SecureRandom.hex(32), pdf_data: "%PDF-fake"
    )
  end

  def item(id: "ii_1")
    { invoice_item_id: id, amount_cents: 14_900, currency: "usd" }
  end

  test "record! writes one ledger row from an already-created invoice item" do
    r = report
    overage = PacketOverage.record!(organization: @organization, compliance_report: r, invoice_item: item)

    assert_equal @organization, overage.organization
    assert_equal r, overage.compliance_report
    assert_equal "ii_1", overage.stripe_invoice_item_id
    assert_equal 14_900, overage.amount_cents
  end

  test "record! is idempotent on the compliance report" do
    r = report
    first = PacketOverage.record!(organization: @organization, compliance_report: r, invoice_item: item(id: "ii_1"))
    second = PacketOverage.record!(organization: @organization, compliance_report: r, invoice_item: item(id: "ii_2"))

    assert_equal first.id, second.id
    assert_equal "ii_1", second.reload.stripe_invoice_item_id
    assert_equal 1, PacketOverage.where(compliance_report: r).count
  end

  test "the unique index rejects a second row for the same report" do
    r = report
    PacketOverage.create!(organization: @organization, compliance_report: r, stripe_invoice_item_id: "ii_1", amount_cents: 100)

    assert_raises(ActiveRecord::RecordNotUnique) do
      PacketOverage.create!(organization: @organization, compliance_report: r, stripe_invoice_item_id: "ii_2", amount_cents: 100)
    end
  end
end
