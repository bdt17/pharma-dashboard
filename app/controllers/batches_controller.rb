class BatchesController < ApplicationController
  def index
    render plain: "Batches OK", status: 200
  end
end
