module Api
  class AiController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def predict_excursion
      render json: { status: 'AI prediction', risk: 0.12 }, status: :ok
    end
  end
end
