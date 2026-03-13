class BatchesController < ApplicationController
  def index
    respond_to do |format|
      format.html { render layout: "application", inline: "<h1>Batches Dashboard</h1><p>✅ Working!</p>" }
      format.pdf  { render plain: "PDF OK" }
      format.all  { render plain: "Batches OK" }
    end
  end
end
