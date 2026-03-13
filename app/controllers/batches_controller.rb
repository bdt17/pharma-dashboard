class BatchesController < ApplicationController
  def index
    respond_to do |format|
      format.html { render layout: "application" }
      format.pdf { render plain: "PDF Chain of Custody OK - Download via /batches/1/chain-of-custody.pdf", layout: false }
    end
  end
end
