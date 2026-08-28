class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Two-factor: mandatory for admins and pharmacists (User#two_factor_required?),
  # opt-in for everyone else. An enrolled user must clear the challenge each
  # session; a required-role user who hasn't enrolled is pushed to setup. Other
  # users are unaffected. The two_factor/* controllers opt out (see
  # TwoFactor::BaseController).
  before_action :enforce_two_factor

  helper_method :current_organization

  private

  def current_organization
    current_user&.organization
  end

  def enforce_two_factor
    return unless user_signed_in?
    # The JSON API is browser-session authenticated today; a 302 to an HTML
    # page would be a useless response there. Leave it on password-session
    # auth -- token auth with its own second factor is a separate change.
    return if request.format.json? || request.path.start_with?("/api/")
    return if devise_controller?
    return if two_factor_satisfied?

    if current_user.otp_enabled?
      redirect_to new_two_factor_challenge_path
    elsif current_user.two_factor_required?
      redirect_to two_factor_setup_path,
        alert: "Two-factor authentication is required for your role. Set it up to continue."
    end
  end

  # True once the user has passed the second factor in this login session.
  # Stored in the Warden user session so Warden clears it on logout, and
  # cleared on every fresh password login (config/initializers/two_factor.rb).
  def two_factor_satisfied?
    warden.session(:user)["mfa_passed"] == true
  rescue StandardError
    false
  end

  def mark_two_factor_satisfied!
    warden.session(:user)["mfa_passed"] = true
  end

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "You are not authorized to do that." }
      format.json { render json: { error: "not authorized" }, status: :forbidden }
      format.any { head :forbidden }
    end
  end
end
