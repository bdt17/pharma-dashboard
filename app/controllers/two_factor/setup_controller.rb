module TwoFactor
  # First-time enrollment: show the QR / manual key, then confirm one code to
  # switch the user to enabled and hand back their backup codes.
  class SetupController < BaseController
    before_action :redirect_if_already_enrolled

    def show
      current_user.generate_otp_secret!
    end

    def create
      if current_user.verify_and_consume_otp!(params[:otp_code])
        codes = current_user.enable_two_factor!
        mark_two_factor_satisfied!
        flash[:backup_codes] = codes
        redirect_to two_factor_backup_codes_path
      else
        flash.now[:alert] = "That code didn't match. Scan the QR code again and enter the current 6-digit code."
        render :show, status: :unprocessable_content
      end
    end

    private

    def redirect_if_already_enrolled
      return unless current_user.otp_enabled?

      redirect_to(two_factor_satisfied? ? dashboard_path : new_two_factor_challenge_path)
    end
  end
end
