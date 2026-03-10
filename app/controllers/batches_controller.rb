class BatchesController < ApplicationController
  respond_to :html, :pdf

  def index
    @batches = Batch.all  # Your DEA chain-of-custody batches
    respond_to do |format|
      format.html { render 'batches/index' }
      format.pdf do
        render pdf: "batches_#{Date.today}",
               template: "batches/index",
               layout: "pdf",
               disposition: "attachment",
               encoding: "UTF-8"
      end
    end
  end
end
