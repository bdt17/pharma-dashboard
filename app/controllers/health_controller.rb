class HealthController < ApplicationController
  def index
    render json: {status: 'ok', rails: '8.1.2', phase: '8-live', puma: '10000'}
  end
end
