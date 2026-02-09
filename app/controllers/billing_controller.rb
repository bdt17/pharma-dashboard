class BillingController < ApplicationController
  def index
    render plain: "$99/mo per vehicle\nLive GPS ✓ FDA Compliance ✓\nsales@thomasinformationtechnology.com\nReply: Demo ready → $5K setup"
  end
end
