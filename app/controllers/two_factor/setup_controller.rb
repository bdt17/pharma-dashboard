module TwoFactor
  # Manage two-factor for the current user: enroll (show the QR / manual key,
  # then confirm one code), or -- for a role that isn't required to keep it --
  # turn it back off.
  class SetupController < BaseController
    # An enrolled user manages two-factor only after clearing the challenge
    # this session -- otherwise a password alone could reach the disable form.
    before_action :require_challenge_if_enrolled

    def show
      current_user.generate_otp_secret! unless current_user.otp_enabled?
    end

    def create
      if current_user.otp_enabled?
        redirect_to two_factor_setup_path, notice: "Two-factor authentication is already on."
      elsif current_user.verify_and_consume_otp!(params[:otp_code])
        codes = current_user.enable_two_factor!
        mark_two_factor_satisfied!
        flash[:backup_codes] = codes
        redirect_to two_factor_backup_codes_path
      else
        flash.now[:alert] = "That code didn't match. Enter the current 6-digit code from your authenticator app -- it changes every 30 seconds."
        render :show, status: :unprocessable_content
      end
    end

    def destroy
      if current_user.two_factor_required?
        redirect_to two_factor_setup_path,
          alert: "Two-factor authentication is required for your role and can't be turned off."
      elsif current_user.verify_second_factor(params[:otp_code])
        current_user.disable_two_factor!
        redirect_to dashboard_path, notice: "Two-factor authentication has been turned off."
      else
        flash.now[:alert] = "That code didn't match, so two-factor authentication is still on."
        render :show, status: :unprocessable_content
      end
    end

    private

    def require_challenge_if_enrolled
      return unless current_user.otp_enabled?
      return if two_factor_satisfied?

      redirect_to new_two_factor_challenge_path
    end
  end
end
