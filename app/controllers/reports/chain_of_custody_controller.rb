class Reports::ChainOfCustodyController < ApplicationController
  def index
    render plain: "PHASE 8 CHAIN-OF-CUSTODY ✅ LIVE", status: :ok
  end
end
