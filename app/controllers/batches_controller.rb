class BatchesController < ApplicationController
  def index
    @batches = Batch.all
  end

  def chain_of_custody
    batch = Batch.find(params[:id])
    pdf_data = PdfChainOfCustodyGenerator.new(batch).generate
    
    send_data pdf_data,
      filename: "chain-of-custody-#{batch.lot_number}.pdf",
      type: 'application/pdf',
      disposition: 'inline'
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Batch not found' }, status: 404
  end
end
  def chain_of_custody
    @batch = Batch.find_by(id: params[:id]) || Batch.first
    return render json: {error: 'No batches'}, status: 404 unless @batch
    
    pdf_data = PdfChainOfCustodyGenerator.new(@batch).generate rescue "PDF Error"
    
    send_data pdf_data,
      filename: "chain-of-custody-#{@batch.lot_number || 'DEMO'}.pdf",
      type: 'application/pdf',
      disposition: 'inline'
  rescue
    render json: {error: 'Batch not found'}, status: 404
  end
