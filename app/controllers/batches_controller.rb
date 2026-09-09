class BatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_batch, only: %i[edit update]

  # /batches.pdf never had a real implementation behind it -- the action
  # just rendered placeholder text ("Batches - Phase 10 Enterprise SaaS")
  # to anyone who hit the route, unauthenticated. The real, authenticated,
  # org-scoped batch data (counts, active/non-compliant batches, recent
  # custody activity) already lives on the dashboard
  # (DashboardController#index) -- send people there instead of
  # continuing to serve fake content from a redundant stub. A real
  # "export batches as PDF" feature, if wanted, is a separate build.
  def index
    redirect_to dashboard_path
  end

  # Self-serve batch (shipment) registration -- the piece of fleet setup
  # that never existed, same gap #170 closed for vehicles. There's no
  # batch index/show page to land on afterward (see #index above), so
  # create/update both redirect into the batch's custody history, which
  # is the closest thing to a batch detail page this app has.
  def new
    @batch = Batch.new
    authorize @batch
  end

  def create
    @batch = current_organization.batches.build(batch_params)
    assign_scoped_associations
    authorize @batch

    if @batch.save
      redirect_to batch_custody_logs_path(@batch), notice: "Added lot #{@batch.lot_number}."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @batch
  end

  def update
    authorize @batch
    @batch.assign_attributes(batch_params)
    assign_scoped_associations

    if @batch.save
      redirect_to batch_custody_logs_path(@batch), notice: "Updated lot #{@batch.lot_number}."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # The one real chain-of-custody PDF: real batch data, real custody
  # history, real audit trail -- generating it is itself an audited event.
  def chain_of_custody
    batch = Batch.find(params[:id])
    authorize batch, :show?

    pdf_data = PdfChainOfCustodyGenerator.new(batch).generate

    AuditLog.record!(
      event: "chain_of_custody_pdf_generated",
      user: current_user,
      batch: batch,
      ip_address: request.remote_ip
    )

    send_data pdf_data,
              filename: "chain-of-custody-#{batch.lot_number}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def set_batch
    @batch = current_organization.batches.find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(:lot_number, :name, :expiry)
  end

  # vehicle_id/driver_id are handled separately from batch_params rather
  # than mass-assigned: both must resolve to a record in the signed-in
  # user's own organization, not whatever id a submitted form happens to
  # carry. A blank or unresolved vehicle leaves @batch.vehicle nil, which
  # the required belongs_to then rejects with a normal validation error;
  # a blank or unresolved driver just clears/leaves the assignment
  # unassigned (optional).
  def assign_scoped_associations
    vehicle_id = params.dig(:batch, :vehicle_id).presence
    driver_id = params.dig(:batch, :driver_id).presence

    @batch.vehicle = vehicle_id && current_organization.vehicles.find_by(id: vehicle_id)
    @batch.driver = driver_id && current_organization.users.driver.find_by(id: driver_id)
  end
end
