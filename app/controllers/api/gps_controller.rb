class Api::GpsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    render json: {
      endpoint: "gps",
      status: "ok",
      received_at: Time.current,
      payload: params.permit!.to_h
    }
  end
end
