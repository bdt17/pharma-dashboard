class BatchesController < ApplicationController
  def index
    render html: "<h1>💉 Batches Dashboard</h1><p>LOT-PHARMA-20260217 LIVE</p>".html_safe, layout: true
  end
end
