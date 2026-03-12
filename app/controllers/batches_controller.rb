class BatchesController < ApplicationController
  def index
    @batches = Batch.all

    respond_to do |format|
      format.html # Uses standard application.html.erb layout
      format.pdf do
        render pdf: "batches_report", 
               layout: "pdf.html.erb",
               page_size: 'A4'
      end
    end
  end
end
