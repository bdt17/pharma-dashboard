# Operator diagnostics: integration/config health at a glance, so a gap
# like "SMTP was never configured" is visible here instead of surfacing as
# a broken signup. Deliberately gated to an explicit OPERATOR_EMAILS
# allowlist -- until that env var names someone, the page 404s and doesn't
# exist as far as the rest of the world is concerned. Every account can
# self-register as an admin, so "admin" alone is not enough to see env-var
# state and cross-organization counts.
class OpsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_operator

  def index
    @groups = Ops::Diagnostics.call
  end

  def test_email
    OpsMailer.test_message(to: current_user.email).deliver_now
    redirect_to ops_path, notice: "Test email sent to #{current_user.email}. Check your inbox (and spam)."
  rescue StandardError => e
    Rails.logger.error("OpsController#test_email failed: #{e.class}: #{e.message}")
    redirect_to ops_path, alert: "Test email failed: #{e.class}: #{e.message}"
  end

  private

  def require_operator
    return if operator_emails.include?(current_user.email.to_s.strip.downcase)

    head :not_found
  end

  def operator_emails
    ENV["OPERATOR_EMAILS"].to_s.split(/[,\s]+/).map { |e| e.strip.downcase }.reject(&:empty?)
  end
end
