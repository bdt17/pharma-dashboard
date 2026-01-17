module Api
  class GpsController < Api::BaseController
    def create
      render json: {
        status: 'received',
        message: 'Phase 14 GPS LIVE 🚛',
        position: {
          lat: params[:lat]&.to_f || 33.4484,
          lng: params[:lng]&.to_f || -112.0740,
          speed: params[:speed]&.to_f || 65.0,
          batch_id: params[:batch_id]
        }
      }, status: :ok
    end
  end
end
