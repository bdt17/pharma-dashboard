require "test_helper"

class ComplianceReportTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    @user = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  def sha256(string)
    Digest::SHA256.hexdigest(string)
  end

  test "requires a version, content_hash, and pdf_data" do
    report = ComplianceReport.new(batch: @batch, organization: @organization, generated_by: @user)
    assert_not report.valid?
    assert_includes report.errors[:version], "can't be blank"
    assert_includes report.errors[:content_hash], "can't be blank"
    assert_includes report.errors[:pdf_data], "can't be blank"
  end

  test "rejects a content_hash that isn't a real SHA-256 hex digest" do
    report = ComplianceReport.new(batch: @batch, organization: @organization, generated_by: @user, version: 1, content_hash: "not-a-hash", pdf_data: "%PDF-fake")
    assert_not report.valid?
    assert_includes report.errors[:content_hash], "must be a 64-character SHA-256 hex digest"
  end

  test "rejects a duplicate version for the same batch" do
    ComplianceReport.create!(batch: @batch, organization: @organization, generated_by: @user, version: 1, content_hash: sha256("v1"), pdf_data: "%PDF-fake")
    dupe = ComplianceReport.new(batch: @batch, organization: @organization, generated_by: @user, version: 1, content_hash: sha256("v1-again"), pdf_data: "%PDF-fake")

    assert_not dupe.valid?
    assert_includes dupe.errors[:version], "has already been taken"
  end

  test "the same version number is fine on a different batch" do
    other_batch = Batch.create!(lot_number: "LOT-2", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    ComplianceReport.create!(batch: @batch, organization: @organization, generated_by: @user, version: 1, content_hash: sha256("a"), pdf_data: "%PDF-fake")

    other = ComplianceReport.new(batch: other_batch, organization: @organization, generated_by: @user, version: 1, content_hash: sha256("b"), pdf_data: "%PDF-fake")
    assert other.valid?
  end

  test "is immutable -- cannot be updated after creation" do
    report = ComplianceReport.create!(batch: @batch, organization: @organization, generated_by: @user, version: 1, content_hash: sha256("a"), pdf_data: "%PDF-fake")

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      report.update!(content_hash: sha256("tampered"))
    end
  end

  test ".create_next_version! issues version 1 with no previous_hash for a batch's first report" do
    report = ComplianceReport.create_next_version!(batch: @batch, generated_by: @user, content_hash: sha256("first"), pdf_data: "%PDF-fake")

    assert_equal 1, report.version
    assert_nil report.previous_hash
    assert_equal @organization, report.organization
    assert_equal "%PDF-fake", report.pdf_data
  end

  test ".create_next_version! chains each new version to the previous one's hash" do
    first = ComplianceReport.create_next_version!(batch: @batch, generated_by: @user, content_hash: sha256("v1"), pdf_data: "%PDF-fake-1")
    second = ComplianceReport.create_next_version!(batch: @batch, generated_by: @user, content_hash: sha256("v2"), pdf_data: "%PDF-fake-2")

    assert_equal 2, second.version
    assert_equal first.content_hash, second.previous_hash
  end
end
