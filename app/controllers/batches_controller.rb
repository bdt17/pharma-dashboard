class BatchesController < ApplicationController
  def index
    @batches = Batch.all
  end

  def show
    @batch = Batch.find(params[:id])
  end

  def chain_of_custody
    @batch = Batch.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "custody_#{@batch.id}",
               template: "batches/chain_of_custody",
               layout: "pdf.html",
               page_size: "A4"
      end
    end
  end
end
