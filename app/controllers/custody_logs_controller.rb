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

    if @custody_log.save
      AuditLog.record!(
        event: "custody_log_created",
        user: current_user,
        batch: @batch,
        ip_address: request.remote_ip,
        data: { action_type: @custody_log.action_type, location: @custody_log.location }
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
    params.require(:custody_log).permit(:action_type, :handler_name, :location, :condition_notes)
  end
end
