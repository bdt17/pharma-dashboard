module TwoFactor
  # Shared setup for the enrollment / challenge / backup-code screens: the user
  # must be signed in, but these controllers are exempt from the
  # enforce_two_factor gate itself (otherwise reaching them would loop).
  class BaseController < ApplicationController
    before_action :authenticate_user!
    skip_before_action :enforce_two_factor

    layout "application"

    private

    # Call after a wrong code. Once too many have been entered the account is
    # locked (see TwoFactorAuthentication#record_failed_second_factor!), so
    # end this password-only session too. Returns true if it did.
    def locked_out_after_failed_code?
      return false unless current_user.record_failed_second_factor!

      sign_out(:user)
      redirect_to new_user_session_path,
        alert: "Too many incorrect codes. Your account is locked for #{Devise.unlock_in.inspect}."
      true
    end

    def mark_passed_and_redirect(default_path)
      mark_two_factor_satisfied!
      redirect_to(stored_location_for(:user) || default_path)
    end
  end
end
