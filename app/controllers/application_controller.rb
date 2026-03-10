class ApplicationController < ActionController::Base
  def not_found
    render plain: "Not Found", status: 404
  end
end
