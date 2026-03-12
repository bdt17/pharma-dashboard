class BatchesController < ApplicationController
  def index
    # PDF Chain of Custody - MONEY MAKER
    respond_to do |format|
      format.pdf do
        render pdf: "batches_#{Date.today}", template: "batches/index"
      end
    end
  end
  
  def chain_of_custody
    @batch_id = params[:id]
    respond_to do |format|
      format.pdf do
        render pdf: "chain_of_custody_batch_#{@batch_id}", 
               template: "batches/chain_of_custody",
               layout: 'pdf'
      end
    end
  end
end

  def coc_pdf
    @batch = Batch.find(params[:id])
    respond_to do |format|
      format.pdf do
        html = render_to_string(partial: 'batches/coc_pdf', layout: false, formats: [:html])
        kit = PDFKit.new(html)
        send_data(kit.to_pdf, filename: "coc_#{@batch.id}.pdf", type: 'application/pdf', disposition: 'attachment')
      end
    end
  end

  def test_pdf
    respond_to do |format|
      format.pdf do
        render pdf: "test", layout: "pdf"
      end
    end
  end

  def coc_pdf
    @batch = Batch.find(params[:id])
    respond_to do |format|
      format.pdf do
        html = render_to_string(partial: 'batches/coc_pdf', layout: false, formats: [:html])
        kit = PDFKit.new(html)
        send_data(kit.to_pdf, filename: "coc_#{@batch.id}.pdf", type: 'application/pdf', disposition: 'attachment')
      end
    end
  end
