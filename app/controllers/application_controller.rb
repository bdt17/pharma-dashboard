class ApplicationController < ActionController::Base
  # Devise strong parameters for login/signup (fixes 422 error)
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks (Rails default)
  protect_from_forgery with: :exception

  # Custom error pages
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::RoutingError, with: :routing_error

  protected

  def configure_permitted_parameters
    # Fix Devise 422 login errors
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :password_confirmation, :name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :current_password, :name])
  end

  private

  def record_not_found
    render plain: "404 - Batch/Vehicle not found", status: :not_found
  end

  def routing_error
    render plain: "404 - Route not found", status: :not_found
  end
end
