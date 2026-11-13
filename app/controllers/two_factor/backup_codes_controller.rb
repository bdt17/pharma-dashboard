module TwoFactor
  # One-time display of backup codes right after enrollment, and later
  # regeneration from the same screen. Only reachable once the user has
  # cleared the second factor this session.
  class BackupCodesController < BaseController
    before_action :require_enrolled_and_verified

    def show
      # Set by SetupController#create (enrollment) or BackupCodesController#create
      # (regeneration). Absent on a plain visit -- the view then just offers to
      # regenerate.
      @backup_codes = flash[:backup_codes]
      # Right after enrollment, "Continue" goes back to what they were doing
      # when the two-factor gate stopped them (ApplicationController).
      @continue_path = (take_two_factor_return_to if @backup_codes) || dashboard_path
    end

    def create
      flash[:backup_codes] = current_user.generate_backup_codes!
      redirect_to two_factor_backup_codes_path
    end

    private

    def require_enrolled_and_verified
      return if current_user.otp_enabled? && two_factor_satisfied?

      redirect_to two_factor_setup_path
    end
  end
end
