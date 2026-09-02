# The delivery log for one webhook endpoint, plus the "Re-send" action.
# Same access rules as WebhookEndpointsController: any signed-in member of
# the organization can read the log; only an admin can replay a delivery.
class WebhookDeliveriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_endpoint
  before_action :require_admin, only: :replay

  PAGE_SIZE = 100

  def index
    @deliveries = @endpoint.deliveries.recent.limit(PAGE_SIZE)
  end

  # Re-send the exact envelope that was recorded, as a new delivery linked
  # back to the original. The receiver dedupes on the (unchanged) envelope
  # id, so a replay is safe to trigger even if the first attempt actually
  # landed.
  def replay
    original = @endpoint.deliveries.find(params[:id])
    replay = @endpoint.deliveries.create!(
      event: original.event,
      event_id: original.event_id,
      payload: original.payload,
      replayed_from: original
    )
    WebhookDeliveryJob.perform_later(replay.id)
    redirect_to webhook_endpoint_deliveries_path(@endpoint), notice: "Re-sent #{original.event} (#{original.event_id})."
  end

  private

  def set_endpoint
    @endpoint = current_organization.webhook_endpoints.find(params[:webhook_endpoint_id])
  end

  def require_admin
    return if current_user.admin?

    redirect_to webhook_endpoint_deliveries_path(@endpoint), alert: "Only an organization admin can re-send a delivery."
  end
end
