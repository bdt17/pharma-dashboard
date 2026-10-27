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
end
