class Api::MarketplaceController < ApplicationController
  skip_before_action :verify_authenticity_token
  # protect_from_forgery removed - API controllers don't need CSRF
  
  def index
    render json: { status: 'Phase 14 Marketplace API LIVE' }
  end
end
