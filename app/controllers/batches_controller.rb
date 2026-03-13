class BatchesController < ApplicationController
  def index
    render plain: "💉 BATCHES LIVE - Chain of Custody Tracking", layout: "application"
  end
  
  def chain_of_custody
    @batch_id = params[:id]
    render plain: "🔗 BATCH #{params[:id]} CHAIN-OF-CUSTODY REPORT", layout: "application"
  end
end
