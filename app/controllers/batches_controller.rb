class BatchesController < ApplicationController
  def index
    @batches = Batch.limit(10) rescue []
    render plain: "BATCHES OK (#{@batches.size})"
  end
end
