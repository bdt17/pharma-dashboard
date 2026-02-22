class ApplicationController < ActionController::Base
  skip_before_action :authenticate_user!
  protect_from_forgery prepend: true
  
  def root
  end
end
