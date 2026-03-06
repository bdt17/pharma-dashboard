class BatchesController < ApplicationController
  before_action :set_batch, only: [:show, :custody_report, :coc_pdf, :edit, :update, :destroy]

def index
  @batches = Batch.all
  respond_to do |format|
    format.html
    format.pdf do
      # Raw PDF - matches your chain-of-custody style
      pdf_content = <<~PDF
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>endobj
4 0 obj<</Length 500>>stream
BT /F1 20 Tf
80 750 Td (PHARMA TRANSPORT - BATCHES LIST) Tj
80 720 Td (Generated: #{Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')}) Tj
80 690 Td (Total Batches: #{@batches.count}) Tj
80 660 Td (Active: #{@batches.where(status: 'active').count}) Tj
80 630 Td (In Transit: #{@batches.where(status: 'in_transit').count}) Tj
80 600 Td (Completed: #{@batches.where(status: 'completed').count}) Tj
ET endstream endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Size 6/Root 1 0 R>>%%EOF
      PDF

      send_data pdf_content,
        filename: "Pharma-Batches-#{Date.today}.pdf",
        type: 'application/pdf',
        disposition: 'attachment'
    end
  end
end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @batch = Batch.new
  end

  def create
    @batch = Batch.new(batch_params)
    if @batch.save
      redirect_to @batch, notice: 'Batch created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @batch.update(batch_params)
      redirect_to @batch, notice: 'Batch updated.'
    else
      render :edit
    end
  end

  def destroy
    @batch.destroy
    redirect_to batches_path, notice: 'Batch deleted.'
  end

def batches_pdf
  @batches = Batch.all
  respond_to do |format|
    format.pdf do
      pdf = render_to_string(template: 'batches/index', formats: [:html])
      send_data pdf, 
        filename: "Pharma-Batches-#{Date.today}.pdf",
        type: 'application/pdf',
        disposition: 'attachment'
    end
  end
end

def custody_report
  respond_to do |format|
    format.html { render 'chain_of_custody' }
    format.pdf  { render :custody_report_pdf } # Your raw PDF
  end
end

  def custody_report
    respond_to do |format|
      format.html { render plain: "Batch #{@batch.id} Chain of Custody HTML" }
      format.pdf do
        vehicle_info = @batch.vehicle&.plate || @batch.vehicle_id.to_s || 'N/A'
        pdf_content = <<~PDF
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>endobj
4 0 obj<</Length 500>>stream
BT /F1 20 Tf
80 750 Td (FDA 21 CFR Part 11 - CHAIN OF CUSTODY) Tj
80 720 Td (Batch ID: #{@batch.id}) Tj
80 690 Td (Lot: #{@batch.lot_number || "LOT-#{@batch.id}"}) Tj
80 660 Td (Status: #{@batch.status || 'IN_TRANSIT'}) Tj
80 630 Td (Vehicle: #{vehicle_info}) Tj
80 600 Td (Temp: #{@batch.temperature_celsius || '2-8C'}) Tj
80 570 Td (DEA: #{@batch.dea_compliant ? 'YES' : 'NO'}) Tj
80 500 Td (Generated: #{Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')}) Tj
ET endstream endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Size 6/Root 1 0 R>>%%EOF
        PDF

        send_data pdf_content,
          filename: "CoC-Raw-Batch#{@batch.id}.pdf",
          type: 'application/pdf',
          disposition: 'inline'
      end
    end
  end

  def coc_pdf
    vehicle_info = @batch.vehicle&.plate || @batch.vehicle_id.to_s || 'N/A'
    pdf_content = <<~PDF
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>endobj
4 0 obj<</Length 500>>stream
BT /F1 20 Tf
80 750 Td (FDA 21 CFR Part 11 - CHAIN OF CUSTODY) Tj
80 720 Td (Batch ID: #{@batch.id}) Tj
80 690 Td (Lot: #{@batch.lot_number || "LOT-#{@batch.id}"}) Tj
80 660 Td (Status: #{@batch.status || 'IN_TRANSIT'}) Tj
80 630 Td (Vehicle: #{vehicle_info}) Tj
80 600 Td (Temp: #{@batch.temperature_celsius || '2-8C'}) Tj
80 570 Td (DEA: #{@batch.dea_compliant ? 'YES' : 'NO'}) Tj
80 500 Td (Generated: #{Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')}) Tj
ET endstream endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Size 6/Root 1 0 R>>%%EOF
    PDF

    send_data pdf_content,
      filename: "CoC-Batch#{@batch.id}.pdf",
      type: 'application/pdf',
      disposition: 'attachment'
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Batch not found: #{params[:id]}"
    redirect_to batches_path, alert: 'Batch not found.'
  end

  def batch_params
    params.require(:batch).permit(
      :lot_number,
      :status,
      :vehicle_id,
      :temperature_celsius,
      :name,
      :batch_number,
      :organization_id,
      :tenant_id,
      :ndc_code,
      :expiry_date,
      :signed_at,
      :signed_by,
      :dea_compliant
    )
  end
end
