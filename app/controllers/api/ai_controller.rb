module Api
  class AiController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def predict_excursion
      render json: { 
        status: 'AI prediction', 
        risk_score: 0.12,
        batch_id: params[:batch_id]
      }, status: :ok
    end
  end
end
