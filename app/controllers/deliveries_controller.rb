# Driver mode's home screen: the shipments still out, one tap from
# recording the pickup or the delivery. A driver sees only what's assigned
# to them; anyone else in the organization sees every active shipment.
class DeliveriesController < ApplicationController
  before_action :authenticate_user!

  def index
    batches = policy_scope(Batch).active.includes(:vehicle, :driver, :custody_logs).order(:created_at)
    batches = batches.where(driver: current_user) if current_user.driver?
    @batches = batches
  end

  # Admin-only: how much GPS a delivery keeps (Organization::DELIVERY_GPS_PRECISIONS).
  def update_privacy
    return redirect_to(deliveries_path, alert: "Only an admin can change delivery privacy.") unless current_user.admin?

    precision = params[:delivery_gps_precision].to_s
    if current_organization.update(delivery_gps_precision: precision)
      AuditLog.record!(event: "delivery_gps_precision_changed", user: current_user, ip_address: request.remote_ip,
                       data: { delivery_gps_precision: precision })
      redirect_to deliveries_path(anchor: "privacy"), notice: "Delivery location precision: #{Organization::DELIVERY_GPS_PRECISIONS[precision]}."
    else
      redirect_to deliveries_path(anchor: "privacy"), alert: "Choose one of the listed options."
    end
  end
end
