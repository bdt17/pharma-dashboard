class CustodyLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_batch
  before_action :set_custody_log, only: [ :show ]

  def index
    authorize @batch, :show?
    @custody_logs = @batch.custody_logs
  end

  def show
    authorize @batch, :show?
  end

  def new
    authorize @batch, :record_custody?
    @custody_log = @batch.custody_logs.build
  end

  def create
    authorize @batch, :record_custody?
    @custody_log = @batch.custody_logs.build(custody_log_params)
    stamp_signature_metadata

    if @custody_log.save
      AuditLog.record!(
        event: "custody_log_created",
        user: current_user,
        batch: @batch,
        ip_address: request.remote_ip,
        data: { action_type: @custody_log.action_type, location: @custody_log.location }
      )

      # A recorded delivery is the trigger for the shipment's formal
      # Compliance Packet -- generated in the background so a slow PDF
      # render never holds up the signature-capture request.
      if @custody_log.action_type == "delivered"
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
      signature_data: [ :image, :signer_name, :signer_role ]
    )
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
