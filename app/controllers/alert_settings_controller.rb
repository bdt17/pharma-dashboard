# Manage the phone numbers that get an SMS when one of the organization's
# shipments starts a temperature excursion. Email alerts to admins and
# pharmacists are always on and not configured here -- this page is only
# the opt-in SMS layer, which is a Pro/Compliance-tier feature.
class AlertSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin, only: %i[create destroy test quiet_hours]

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

  def test
    unless current_organization&.alert_sms_available?
      redirect_to alert_settings_path, alert: "SMS alerts are available on the Pro and Compliance plans."
      return
    end

    recipient = current_organization.alert_recipients.find(params[:id])
    SmsTestJob.perform_later(recipient.id)
    redirect_to alert_settings_path,
      notice: "Test message queued for #{recipient.phone}. If it doesn't arrive, check /ops and the Twilio message logs."
  end

  # Turns SMS quiet hours on/off and (if given) sets the timezone quiet
  # hours are computed against -- see Organization#sms_quiet_hours_active?.
  # A blank time_zone param is left alone rather than cleared, so turning
  # the toggle on/off from the checkbox alone doesn't wipe out a timezone
  # already on file.
  def quiet_hours
    enabled = ActiveModel::Type::Boolean.new.cast(params.dig(:organization, :sms_quiet_hours_enabled))
    attrs = { sms_quiet_hours_enabled: enabled }
    time_zone = params.dig(:organization, :time_zone)
    attrs[:time_zone] = time_zone if time_zone.present?

    if current_organization.update(attrs)
      redirect_to alert_settings_path,
        notice: enabled ? "Quiet hours are on. Excursion texts between #{Organization::SMS_QUIET_HOURS_START % 12}pm and #{Organization::SMS_QUIET_HOURS_END}am local will wait until morning." :
                           "Quiet hours are off. Excursion texts go out immediately, any time."
    else
      redirect_to alert_settings_path, alert: current_organization.errors.full_messages.to_sentence
    end
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
