class HealthController < ApplicationController
  def index
    render json: { 
      status: 'ok', 
      rails: '8.1.2', 
      phase: '8-enterprise', 
      database: 'connected',
      puma: 'live',
      render: 'pharma-beq2'
    }
  end
end
