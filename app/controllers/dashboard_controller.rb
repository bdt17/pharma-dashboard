class DashboardController < ApplicationController
  def index
    @vehicles = [{name: 'AZ Pharma-001', status: 'active'}]
    @batches = [{lot_number: 'LOT-PHARMA-20260211', status: 'in_transit'}]
  end
end
