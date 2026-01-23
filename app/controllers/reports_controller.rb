class ReportsController < ApplicationController
  def chain_of_custody
    @batch_id = params[:id]
    @batch_info = { 
      origin: "Pfizer Phoenix AZ", 
      destination: "CVS #4721",
      driver: "John Doe #TX-7842"
    }
  end
end
