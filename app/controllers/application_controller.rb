class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_organization

  private

  def current_organization
    current_user&.organization
  end

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "You are not authorized to do that." }
      format.json { render json: { error: "not authorized" }, status: :forbidden }
      format.any { head :forbidden }
    end
  end
end
