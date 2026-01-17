class Api::MarketplaceController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    render json: {
      endpoint: "marketplace/bid",
      status: "bid_received",
      bid_id: SecureRandom.uuid,
      received_at: Time.current,
      payload: params.permit!.to_h
    }
  end
end
