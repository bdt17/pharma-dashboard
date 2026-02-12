class ReportsController < ApplicationController
  def chain_of_custody
    @batch = Batch.last || Batch.new(lot_number: "DEMO-#{Time.now.to_i}")
    respond_to do |format|
      format.pdf do
        pdf = WickedPdf.new.pdf_from_string(render_to_string)
        send_data pdf, filename: "chain-of-custody #{@batch.lot_number}.pdf"
      end
    end
  end
end
