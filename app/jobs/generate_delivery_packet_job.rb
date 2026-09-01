# Auto-generates a Compliance Packet when a delivery is recorded, so every
# completed shipment ends up with its formal, hash-chained PDF without
# anyone remembering to click "Generate". Enqueued from
# CustodyLogsController when a `delivered` custody event is saved.
#
# Attributed to the user who recorded the delivery. Honours the same
# monthly quota as the manual path (ComplianceReportQuota): within the
# allowance -- or with a purchased credit -- it generates and consumes;
# over the cap it records a `compliance_packet_autogen_skipped` audit
# entry, which is the organization's cue that it's out of packets.
class GenerateDeliveryPacketJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(custody_log_id, recorded_by_id)
    custody_log = CustodyLog.find_by(id: custody_log_id)
    return unless custody_log&.action_type == "delivered"

    batch = custody_log.batch
    recorded_by = User.find_by(id: recorded_by_id)
    return unless batch && recorded_by

    # Idempotency: a retry of this job, or someone generating a packet by
    # hand between the delivery and this job running, both mean there's
    # nothing left to do.
    return if batch.compliance_reports.where("compliance_reports.created_at >= ?", custody_log.created_at).exists?

    quota = ComplianceReportQuota.new(batch.organization)
    if quota.exceeded?
      AuditLog.record!(
        event: "compliance_packet_autogen_skipped",
        user: recorded_by,
        batch: batch,
        data: { reason: "monthly_allowance_reached", allowance: quota.monthly_allowance }
      )
      return
    end

    credit = quota.credit_to_consume
    report = ComplianceReportGenerator.new(batch).generate!(generated_by: recorded_by).compliance_report
    credit&.consume!

    AuditLog.record!(
      event: "compliance_report_generated",
      user: recorded_by,
      batch: batch,
      data: { version: report.version, content_hash: report.content_hash, trigger: "delivery" }
    )
  end
end
