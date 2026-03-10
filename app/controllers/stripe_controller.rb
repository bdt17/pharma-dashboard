class StripeController < ApplicationController
  def new
  end
  
  def success
    @session = params[:session_id]
  end
end
