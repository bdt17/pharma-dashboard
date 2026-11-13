require "test_helper"

class AuditLogEventLabelTest < ActiveSupport::TestCase
  test "known events read as plain words, unknown ones fall back to the humanized code" do
    assert_equal "Custody event recorded", AuditLog.new(event: "custody_log_created").event_label
    assert_equal "Compliance Packet generated", AuditLog.new(event: "compliance_report_generated").event_label
    assert_equal "Team member invited", AuditLog.new(event: "team_member_invited").event_label
  end
end
