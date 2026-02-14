class HealthController < ApplicationController
  def show
    render plain: "PharmaTransport 2.0 🟢 LIVE", status: :ok
  end
end
