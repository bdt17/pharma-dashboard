class BatchesController < ApplicationController; def index; @title = 'Batches'; end; end

  def chain_of_custody
    @batch = Batch.find(params[:id])
    respond_to do |format|
      format.pdf do
        html = render_to_string(template: "batches/chain_of_custody", layout: "pdf")
        pdf = WickedPdf.new.pdf_from_string(
          html,
          footer: {
            center: "LOT-#{@batch.id} [Page %{page} of %{numpages}]",
            font_size: 10,
            spacing: 5
          }
        )
        send_data pdf, 
                  filename: "CoC-PHARMA-#{@batch.id}-#{Time.current.strftime('%Y%m%d')}.pdf", 
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end
