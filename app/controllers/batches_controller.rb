class BatchesController < ApplicationController
  def index
    @batches = [{id: 1, lot: 'LOT-2026-001', status: 'Active'}]
    render layout: 'application'
  end
end
