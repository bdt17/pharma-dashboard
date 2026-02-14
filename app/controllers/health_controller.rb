class HealthController < ApplicationController
  def show
    render plain: "PharmaTransport 2.0 🟢 LIVE 2026", status: :ok
  end
end
