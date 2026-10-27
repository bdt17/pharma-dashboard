class CustodyLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_batch
  before_action :set_custody_log, only: [ :show ]
  # The one page that may ask for the device's location: driver mode
  # attaches a GPS fix to the event. Every other page keeps the app-wide
  # geolocation=() from config/initializers/content_security_policy.rb.
  after_action :allow_geolocation, only: %i[new create]

  def index
    authorize @batch, :show?
    @custody_logs = @batch.custody_logs
  end

  def show
    authorize @batch, :show?
  end

  def new
    authorize @batch, :record_custody?
    action_type = params[:action_type].presence_in(CustodyLog::ACTION_TYPES) || default_action_type
    @custody_log = @batch.custody_logs.build(action_type: action_type, handler_name: current_user.name.presence || current_user.email)
  end

  def create
    authorize @batch, :record_custody?
    @custody_log = @batch.custody_logs.build(custody_log_params)
    @custody_log.recorded_by = current_user
    stamp_signature_metadata

    if @custody_log.save
      AuditLog.record!(
        event: "custody_log_created",
        user: current_user,
        batch: @batch,
        ip_address: request.remote_ip,
        data: { action_type: @custody_log.action_type, location: @custody_log.location }
      )

      if @custody_log.action_type == "delivered"
        # Nothing else in the app ever advances a batch's own status --
        # Vehicle#current_batch depends on it being something other than
        # "delivered" to know a truck is still out on a run, so without
        # this every batch would stay "active" forever regardless of
        # what custody history says actually happened to it.
        @batch.update!(status: "delivered")

        # The trigger for the shipment's formal Compliance Packet --
        # generated in the background so a slow PDF render never holds
        # up the signature-capture request.
        GenerateDeliveryPacketJob.perform_later(@custody_log.id, current_user.id)
      end

      WebhookDispatcher.publish(
        organization: @batch.organization,
        event: "custody.recorded",
        data: {
          lot_number: @batch.lot_number,
          action_type: @custody_log.action_type,
          handler_name: @custody_log.handler_name,
          location: @custody_log.location,
          signed: @custody_log.signed?,
          temperature_celsius: @custody_log.temperature_celsius&.to_f,
          latitude: @custody_log.latitude&.to_f,
          longitude: @custody_log.longitude&.to_f,
          location_accuracy_m: @custody_log.location_accuracy_m,
          recorded_by: @custody_log.recorded_by&.email,
          recorded_at: @custody_log.timestamp&.iso8601
        }
      )

      redirect_to batch_custody_log_path(@batch, @custody_log), notice: "Custody event recorded."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_batch
    @batch = Batch.find(params[:batch_id])
  end

  def set_custody_log
    @custody_log = @batch.custody_logs.find(params[:id])
  end

  def custody_log_params
    params.require(:custody_log).permit(
      :action_type, :handler_name, :location, :condition_notes,
      :latitude, :longitude, :location_accuracy_m, :temperature_celsius,
      signature_data: [ :image, :signer_name, :signer_role ]
    )
  end

  # Pickup first, then delivery once something has been picked up --
  # what a driver opening this page almost always means to record next.
  def default_action_type
    @batch.custody_logs.exists?(action_type: "pickup") ? "delivered" : "pickup"
  end

  def allow_geolocation
    response.headers["Permissions-Policy"] = response.headers["Permissions-Policy"].to_s.sub("geolocation=()", "geolocation=(self)")
  end

  # signed_at/ip_address are recorded server-side, not trusted from the
  # client -- same principle as AuditLog's ip_address.
  def stamp_signature_metadata
    return unless @custody_log.signature_data.present? && @custody_log.signature_data["image"].present?

    @custody_log.signature_data = @custody_log.signature_data.merge(
      "signed_at" => Time.current.iso8601,
      "ip_address" => request.remote_ip
    )
  end
end
