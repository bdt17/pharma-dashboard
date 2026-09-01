# Manage the phone numbers that get an SMS when one of the organization's
# shipments starts a temperature excursion. Email alerts to admins and
# pharmacists are always on and not configured here -- this page is only
# the opt-in SMS layer, which is a Pro/Compliance-tier feature.
class AlertSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin, only: %i[create destroy]

  def index
    @sms_available = current_organization&.alert_sms_available? || false
    @recipients = current_organization ? current_organization.alert_recipients.order(:created_at) : AlertRecipient.none
    @recipient = AlertRecipient.new
  end

  def create
    unless current_organization&.alert_sms_available?
      redirect_to alert_settings_path, alert: "SMS alerts are available on the Pro and Compliance plans."
      return
    end

    @recipient = current_organization.alert_recipients.build(recipient_params)
    if @recipient.save
      redirect_to alert_settings_path, notice: "Added #{@recipient.label} to SMS alerts."
    else
      @sms_available = true
      @recipients = current_organization.alert_recipients.order(:created_at)
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    recipient = current_organization.alert_recipients.find(params[:id])
    recipient.destroy
    redirect_to alert_settings_path, notice: "Removed #{recipient.label} from SMS alerts."
  end

  private

  def recipient_params
    params.require(:alert_recipient).permit(:label, :phone)
  end

  def require_admin
    return if current_user.admin?

    redirect_to alert_settings_path, alert: "Only an organization admin can change alert recipients."
  end
end
