class BatchesController < ApplicationController
  respond_to :html, :pdf

  def index
    @batches = Batch.all
    respond_to do |format|
      format.html { render 'batches/index' }
      format.pdf do
        render pdf: "batches_#{Date.today}",
               template: "batches/index",
               layout: "pdf"
      end
    end
  end

  # NEW: Chain-of-Custody PDF for test_login.sh
  def chain_of_custody
    @batch = Batch.find(params[:id] || 1)
    respond_to do |format|
      format.pdf do
        render pdf: "coc_#{@batch.id}_#{Date.today}",
               template: "batches/chain_of_custody",
               layout: "pdf"
      end
    end
  end
end
