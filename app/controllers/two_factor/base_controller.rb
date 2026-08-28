module TwoFactor
  # Shared setup for the enrollment / challenge / backup-code screens: the user
  # must be signed in, but these controllers are exempt from the
  # enforce_two_factor gate itself (otherwise reaching them would loop).
  class BaseController < ApplicationController
    before_action :authenticate_user!
    skip_before_action :enforce_two_factor

    layout "application"

    private

    def mark_passed_and_redirect(default_path)
      mark_two_factor_satisfied!
      redirect_to(stored_location_for(:user) || default_path)
    end
  end
end
