# Manage the URLs an organization receives excursion + custody events on.
# A Compliance-tier feature; admin-only for every change. The signing
# secret is shown to admins here (it's a shared HMAC secret, not a
# third-party credential) so they can verify deliveries on their side.
class WebhookEndpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin, only: %i[create destroy enable test]
  before_action :set_endpoint, only: %i[destroy enable test]

  def index
    @available = current_organization&.webhooks_available? || false
    @endpoints = current_organization ? current_organization.webhook_endpoints.order(:created_at) : WebhookEndpoint.none
    @endpoint = WebhookEndpoint.new
  end

  def create
    unless current_organization&.webhooks_available?
      redirect_to webhook_endpoints_path, alert: "Webhooks are available on the Compliance plan."
      return
    end

    @endpoint = current_organization.webhook_endpoints.build(endpoint_params)
    if @endpoint.save
      redirect_to webhook_endpoints_path, notice: "Added #{@endpoint.url}. Deliveries are signed with the secret shown below."
    else
      @available = true
      @endpoints = current_organization.webhook_endpoints.order(:created_at)
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    @endpoint.destroy
    redirect_to webhook_endpoints_path, notice: "Removed #{@endpoint.url}."
  end

  # Re-arm an endpoint that auto-disabled after a run of failures.
  def enable
    @endpoint.update!(active: true, consecutive_failures: 0, last_error: nil)
    redirect_to webhook_endpoints_path, notice: "Re-enabled #{@endpoint.url}."
  end

  def test
    WebhookDeliveryJob.perform_later(@endpoint.id, "webhook.test", {
      id: SecureRandom.uuid, event: "webhook.test", created_at: Time.current.iso8601,
      data: { message: "This is a test delivery from Pharma Transport." }
    })
    redirect_to webhook_endpoints_path, notice: "Test event queued for #{@endpoint.url}."
  end

  private

  def set_endpoint
    @endpoint = current_organization.webhook_endpoints.find(params[:id])
  end

  def endpoint_params
    params.require(:webhook_endpoint).permit(:url)
  end

  def require_admin
    return if current_user.admin?

    redirect_to webhook_endpoints_path, alert: "Only an organization admin can manage webhooks."
  end
end
