class Api::AiController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    render json: {
      endpoint: "ai/predict-excursion",
      status: "prediction_generated",
      risk_score: rand.round(2),
      received_at: Time.current,
      payload: params.permit!.to_h
    }
  end
end
