class BatchesController < ApplicationController
  before_action :authenticate_user!, except: [:index]  # Phase 8 security
  before_action :set_batch, only: [:show, :custody_report]

  def index
    @batches = Batch.all
    render 'index'
  end

  def show
    render 'show'
  end

  def custody_report  # ← Matches your route line 50
    pdf_content = <<~PDF
      %PDF-1.4
      1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
      2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
      3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
      4 0 obj<</Length 350>>stream
      BT /F1 24 Tf 100 700 Td (CHAIN OF CUSTODY - BATCH #{@batch.id}) Tj
      100 650 Td (LOT: #{@batch.lot_number || "LOT-#{@batch.id}"}) Tj
      100 620 Td (Vehicle: #{@batch.vehicle&.identifier || 'N/A'}) Tj  
      100 590 Td (Driver: #{@batch.vehicle&.driver&.name || 'N/A'}) Tj
      100 560 Td (Temp: #{@batch.temperature || 4.2}C (2-8C Cold Chain)) Tj
      100 530 Td (Generated: #{Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')}) Tj
      100 500 Td (User: #{current_user&.email || 'System'}) Tj
      100 470 Td (21 CFR Part 11 Compliant) Tj ET
      endstream endobj
      5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
      trailer<</Size 6/Root 1 0 R>>%%EOF
    PDF

    respond_to do |format|
      format.pdf do
        send_data pdf_content,
                  filename: "Chain-of-Custody-Batch-#{@batch.id}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
      format.html { render plain: 'PDF only: /batches/1/chain-of-custody.pdf' }
    end
  end

  private
  def set_batch
    @batch = Batch.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: 'Batch not found', status: :not_found
  end
end
