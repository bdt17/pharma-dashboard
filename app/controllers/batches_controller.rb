class BatchesController < ApplicationController
  def index
    respond_to do |format|
      format.html { render layout: "application", inline: "<div style=\"padding:2rem\"><h1>Batches Dashboard</h1><p>✅ Thomas IT Chain of Custody</p></div>" }
      format.pdf  { render plain: "PDF OK" }
      format.all  { render plain: "Batches OK" }
    end
  end
end
