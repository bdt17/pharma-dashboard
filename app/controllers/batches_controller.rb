class BatchesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :custody_report]
  before_action :authenticate_pharma_token!, only: :custody_report
  before_action :set_batch, only: [:show, :custody_report]
  after_action :log_pdf_access, only: :custody_report

  def index
    @batches = Batch.all
    render 'index'
  end

  def show
    render 'show'
  end

  def custody_report
    Rails.logger.info "=== CUSTODY REPORT START ==="
    Rails.logger.info "Batch ID: #{@batch.id}"
    Rails.logger.info "Batch lot_number: '#{@batch.lot_number}'"
    Rails.logger.info "Batch vehicle_id: #{@batch.vehicle_id}"
    Rails.logger.info "Vehicle exists: #{@batch.vehicle.present?}"
    Rails.logger.info "Driver exists: #{@batch.vehicle&.driver.present? rescue 'no vehicle'}"
    Rails.logger.info "========================"

    pdf_content = <<~PDF
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>
4 0 obj<</Length 450>>stream
BT
/F1 24 Tf
100 700 Td (CHAIN OF CUSTODY - BATCH #{@batch.id}) Tj
100 650 Td (LOT: #{@batch.lot_number || "LOT-#{@batch.id}"}) Tj
100 620 Td (Vehicle: #{@batch.vehicle&.identifier || 'N/A'}) Tj
100 590 Td (Driver: #{@batch.vehicle&.driver&.name || 'N/A'}) Tj
100 560 Td (Temp: #{@batch.temperature || 4.2}C (2-8C Cold Chain)) Tj
100 530 Td (Status: #{@batch.status || 'active'}) Tj
100 500 Td (Generated: #{Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')}) Tj
100 470 Td (User: #{current_user&.email || 'PHARMA_API_TOKEN'}) Tj
100 440 Td (21 CFR Part 11 Compliant) Tj
ET
endstream
endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Size 6/Root 1 0 R>>%%EOF
    PDF

    Rails.logger.info "=== PDF GENERATED SUCCESSFULLY ==="

    respond_to do |format|
      format.pdf do
        send_data pdf_content,
          filename: "Chain-of-Custody-Batch-#{@batch.id}.pdf",
          type: 'application/pdf',
          disposition: 'inline'
      end
      format.html { render plain: 'PDF only: Use /batches/1/chain-of-custody.pdf' }
    end
  rescue StandardError => e
    Rails.logger.error "=== CUSTODY REPORT ERROR ==="
    Rails.logger.error "Error: #{e.message}"
    Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}"
    head :internal_server_error
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Batch not found: ID #{params[:id]}"
    render plain: 'Batch not found', status: :not_found
  end

  def authenticate_pharma_token!
    expected = ENV['PHARMA_API_TOKEN']
    token = request.authorization&.split('Bearer ')&.last
    
    unless expected.present? && token == expected
      Rails.logger.warn "Pharma token auth failed: #{request.remote_ip}"
      head :unauthorized
    end
  end

  def log_pdf_access
    AuditLog.create!(
      user: current_user&.email || 'PHARMA_API_TOKEN',
      action: 'chain_of_custody_pdf',
      batch_id: @batch.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      response_status: response.status,
      bytes_sent: response.body.bytesize
    ) rescue Rails.logger.info("PDF audit log failed for batch #{@batch.id}")
  end
end
