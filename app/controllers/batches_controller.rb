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
