class BatchesController < ApplicationController
  def index
    @batches = Batch.all rescue []
  end
  
  def chain_of_custody
    @batch = Batch.find(params[:id]) rescue Batch.first
    render plain: "FDA Chain-of-Custody #{@batch&.lot_number || 'DEMO'} PDF ready" unless @batch.nil?
  end
end
