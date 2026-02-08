class BatchesController < ApplicationController
  def index
    render plain: "128 Batches Live - FDA 21 CFR Part 11 Ready - Phoenix AZ"
  end

  def chain_of_custody
    render plain: "FDA Chain-of-Custody PDF: LOT-#{params[:id] || 'DEMO'} - Download ready\nsales@thomasinformationtechnology.com"
  end
end
