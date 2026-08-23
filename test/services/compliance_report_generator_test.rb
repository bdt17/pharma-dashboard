require "test_helper"

class ComplianceReportGeneratorTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    @user = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  test "generates a real PDF and a matching, correctly-hashed ComplianceReport" do
    result = ComplianceReportGenerator.new(@batch).generate!(generated_by: @user)

    assert result.pdf_bytes.start_with?("%PDF"), "expected a real PDF"
    assert result.compliance_report.persisted?
    assert_equal Digest::SHA256.hexdigest(result.pdf_bytes), result.compliance_report.content_hash
  end

  test "sets batch, organization, and generated_by correctly" do
    result = ComplianceReportGenerator.new(@batch).generate!(generated_by: @user)

    assert_equal @batch, result.compliance_report.batch
    assert_equal @organization, result.compliance_report.organization
    assert_equal @user, result.compliance_report.generated_by
  end

  test "each call issues the next version, chained to the previous hash" do
    first = ComplianceReportGenerator.new(@batch).generate!(generated_by: @user)
    second = ComplianceReportGenerator.new(@batch).generate!(generated_by: @user)

    assert_equal 1, first.compliance_report.version
    assert_nil first.compliance_report.previous_hash

    assert_equal 2, second.compliance_report.version
    assert_equal first.compliance_report.content_hash, second.compliance_report.previous_hash
  end

  test "different batches get independent version sequences" do
    other_batch = Batch.create!(lot_number: "LOT-2", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)

    result_a = ComplianceReportGenerator.new(@batch).generate!(generated_by: @user)
    result_b = ComplianceReportGenerator.new(other_batch).generate!(generated_by: @user)

    assert_equal 1, result_a.compliance_report.version
    assert_equal 1, result_b.compliance_report.version
    assert_not_equal result_a.compliance_report.content_hash, result_b.compliance_report.content_hash
  end

  test "recording a compliance report does not depend on custody/audit history existing" do
    assert_empty @batch.custody_logs
    assert_empty @batch.audit_logs

    result = ComplianceReportGenerator.new(@batch).generate!(generated_by: @user)

    assert result.compliance_report.persisted?
  end
end
