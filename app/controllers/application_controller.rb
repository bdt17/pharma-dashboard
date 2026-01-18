class ApplicationController < ActionController::Base
  def health
    render plain: "ok", status: 200
  end
end
