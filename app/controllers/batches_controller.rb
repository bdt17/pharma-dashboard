class BatchesController < ApplicationController
  before_action :authenticate_pharma_token!, only: :custody_report
  before_action :set_batch, only: :custody_report

  def custody_report
    Rails.logger.info "=== CUSTODY REPORT START ==="
    Rails.logger.info "Batch ID: #{@batch.id}"
    Rails.logger.info "Batch data: #{@batch.attributes.inspect}"
    
    pdf_content = <<~PDF
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>
4 0 obj<</Length 450>>stream
BT
/F1 24 Tf
100 700 Td (CHAIN OF CUSTODY - BATCH #{@batch.id}) Tj
100 650 Td (LOT: #{@batch.lot_number || 'LOT-1'}) Tj
100 620 Td (Vehicle: #{@batch.vehicle&.plate || @batch.vehicle&.name || 'N/A'}) Tj
100 590 Td (Temp: #{@batch.temperature_celsius || 4.2}C) Tj
100 560 Td (Status: #{@batch.status || 'active'}) Tj
100 500 Td (Generated: #{Time.now.utc.strftime('%Y-%m-%d %H:%M')}) Tj
ET
endstream
endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Size 6/Root 1 0 R>>%%EOF
    PDF

    Rails.logger.info "=== PDF SUCCESS ==="
    send_data pdf_content, 
      filename: "Chain-of-Custody-Batch-#{@batch.id}.pdf",
      type: 'application/pdf', 
      disposition: 'inline'
  rescue StandardError => e
    Rails.logger.error "=== PDF ERROR: #{e.class} - #{e.message} ==="
    Rails.logger.error e.backtrace.join("\n")
    head :internal_server_error
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
    Rails.logger.info "Batch loaded: #{@batch.id}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Batch NOT FOUND: #{params[:id]}"
    render plain: 'Batch not found', status: :not_found
  end

  def authenticate_pharma_token!
    token = request.authorization&.split('Bearer ')&.last
    expected = ENV['PHARMA_API_TOKEN']
    Rails.logger.info "Token check: got=#{token ? 'YES' : 'NO'}, expected=#{expected.present? ? 'YES' : 'NO'}"
    head :unauthorized unless expected == token
  end
end
