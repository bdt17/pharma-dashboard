class BatchesController < ApplicationController
  def index
    render plain: "Batches Dashboard - LOT-PHARMA-20260217", layout: false, status: 200
  end
end
