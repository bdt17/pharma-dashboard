class ChainOfCustodyController < ApplicationController
  def index
    # Mock data if Batch doesn't exist yet
    @batches = [
      OpenStruct.new(lot_number: "LOT-PHARMA-20260128", status: "In Transit", vehicle: "GV55-001"),
      OpenStruct.new(lot_number: "LOT-PHARMA-20260127", status: "Delivered", vehicle: "GV55-002")
    ]
    render "index"
  end
end
