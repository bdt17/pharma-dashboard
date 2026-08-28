module TwoFactor
  # Post-password step shown on every fresh login for an enrolled user.
  # Accepts a current TOTP or an unused backup code.
  class ChallengeController < BaseController
    before_action :redirect_unless_enrolled

    def new
      redirect_to dashboard_path if two_factor_satisfied?
    end

    def create
      if current_user.verify_second_factor(params[:otp_code])
        mark_passed_and_redirect(dashboard_path)
      else
        flash.now[:alert] = "That code didn't match. Enter the current code from your authenticator app, or one of your backup codes."
        render :new, status: :unprocessable_content
      end
    end

    private

    # An un-enrolled user has nothing to be challenged on -- send them to setup.
    def redirect_unless_enrolled
      redirect_to two_factor_setup_path unless current_user.otp_enabled?
    end
  end
end
