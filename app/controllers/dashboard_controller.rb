# The real operations dashboard: what's actually in the database for the
# signed-in user's organization, not the one-line "Authenticated user:
# email" placeholder this used to be (see the Phase 1 audit).
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    batches = policy_scope(Batch)
    @batch_count = batches.count
    @active_batch_count = batches.active.count
    @non_compliant_batches = batches.non_compliant.order(updated_at: :desc).limit(10)
    @ongoing_excursions = ExcursionEvent.ongoing.where(batch: batches).includes(:batch, :vehicle).recent_first

    vehicles = policy_scope(Vehicle)
    @vehicle_count = vehicles.count
    @vehicles_online_count = vehicles.where("last_ping_at > ?", 15.minutes.ago).count

    @recent_audit_logs = current_organization ? AuditLog.where(user: current_organization.users).order(created_at: :desc).limit(10) : AuditLog.none
    @recent_custody_logs = CustodyLog.joins(:batch).merge(batches).order(timestamp: :desc).limit(10)

    # Mirrors the Billing page's own overage summary -- see
    # BillingController#index and its _overage_summary partial. Shown here
    # too so an org doesn't have to visit Billing just to notice they're
    # accruing extra charges this month.
    @overages_this_month = current_organization&.packet_overages&.this_month || PacketOverage.none
  end
end
