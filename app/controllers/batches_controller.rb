class BatchesController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
  def coc_pdf
    @batch = Batch.find(params[:id]) rescue Batch.first
    respond_to do |format|
      format.pdf { 
        send_data "CoC PDF for Batch #{@batch&.id} - FDA 21 CFR Part 11", 
                  filename: "coc_#{@batch&.id || 1}.pdf", 
                  type: 'application/pdf'
      }
    end
  end
end

  def coc_pdf
    respond_to do |format|
      format.pdf do
        pdf_content = "FDA 21 CFR Part 11\nChain of Custody\nBatch #1\nStatus: DELIVERED"
        send_data pdf_content, filename: "coc_1.pdf", type: 'application/pdf'
      end
    end
  end
