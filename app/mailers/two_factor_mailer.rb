# Security notifications so a user finds out if two-factor is turned on or
# off on their account -- especially if it wasn't them. Triggered from
# User#enable_two_factor! / #disable_two_factor!, so the "off" mail also
# covers an operator reset (TwoFactorReset).
class TwoFactorMailer < ApplicationMailer
  def enabled
    @user = params[:user]
    mail(to: @user.email, subject: "Two-factor authentication was turned on")
  end

  def disabled
    @user = params[:user]
    mail(to: @user.email, subject: "Two-factor authentication was turned off")
  end
end
