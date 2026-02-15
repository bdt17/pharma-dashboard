class BatchesController < ApplicationController
  def index
    render html: '<h1>Batch Tracking</h1><p>127 active shipments</p>'
  end
end
