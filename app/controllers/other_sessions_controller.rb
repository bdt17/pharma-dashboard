# "Sign out other devices" on the Security page: for a lost phone, a shared
# computer someone forgot to sign out of, or a suspected compromise.
# Invalidates every session and remember-me cookie for the account
# (User#sign_out_everywhere!), then re-signs this browser in so the person
# clicking doesn't lose their own session -- or their passed second factor.
class OtherSessionsController < ApplicationController
  include Devise::Controllers::Rememberable

  before_action :authenticate_user!

  def destroy
    remembered = cookies[remember_key(current_user, :user)].present?

    current_user.sign_out_everywhere!
    bypass_sign_in(current_user)
    remember_me(current_user) if remembered

    AuditLog.record!(event: "signed_out_other_sessions", user: current_user, ip_address: request.remote_ip)
    redirect_to two_factor_setup_path, notice: "Signed out of every other device and browser."
  end
end
