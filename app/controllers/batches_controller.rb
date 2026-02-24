class BatchesController < ApplicationController
  def index
    @batches = Batch.all
  end
  
  def custody_report
    @batch = Batch.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        pdf = WickedPdf.new.pdf_from_string(
          render_to_string(template: "batches/custody_report.pdf.erb", layout: "pdf")
        )
        send_data pdf, filename: "chain_of_custody_#{@batch.id}.pdf", 
                  type: "application/pdf", disposition: "attachment"
      end
    end
  end
end
