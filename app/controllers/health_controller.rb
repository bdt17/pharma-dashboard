class HealthController < ApplicationController
  def show
    render plain: "OK - Rails 8.1 LIVE - 25 vehicles - 128 batches - Render production"
  end
end
