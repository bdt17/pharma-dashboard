# Organization-wide compliance overview: real non-compliant batches and a
# real audit trail, replacing the "Compliance OK" stub this used to be.
class ComplianceController < ApplicationController
  before_action :authenticate_user!

  def index
    batches = policy_scope(Batch)
    @non_compliant_batches = batches.non_compliant.order(updated_at: :desc)
    @compliant_count = batches.compliant.count
    @unknown_count = batches.where(temperature_celsius: nil).count
    @audit_logs = current_organization ? AuditLog.where(user: current_organization.users).order(created_at: :desc).limit(25) : AuditLog.none
  end
end
