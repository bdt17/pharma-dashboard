class BillingController < ApplicationController
  def index
    render plain: "$99/mo per vehicle\nLive GPS ✓\nFDA Compliance ✓\nsales@thomasinformationtechnology.com\nStart free trial → Reply for demo"
  end
end
