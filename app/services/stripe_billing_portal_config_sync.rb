# One-time-per-setup script: Stripe's Billing Portal needs at least one
# active Configuration before Stripe::BillingPortal::Session.create will
# work in live mode (test mode gets a usable default for free, live mode
# doesn't). Ensures one exists with the specific features this app's
# customers actually need -- updating a payment method, viewing invoices,
# and canceling -- rather than relying on whatever Stripe's own dashboard
# default happens to allow. Run via
# `bin/rails stripe:sync_billing_portal_config`.
class StripeBillingPortalConfigSync
  def self.call
    new.call
  end

  def call
    return existing_configuration if existing_configuration

    Stripe::BillingPortal::Configuration.create(
      business_profile: { headline: "Pharma Transport billing" },
      features: {
        invoice_history: { enabled: true },
        payment_method_update: { enabled: true },
        subscription_cancel: { enabled: true }
      }
    )
  end

  private

  # is_default is the one Stripe actually uses when a Session is created
  # without an explicit configuration id -- an active-but-not-default
  # configuration (e.g. one left over from clicking around the dashboard)
  # wouldn't actually be what billing_portal_url ends up using.
  def existing_configuration
    @existing_configuration ||= Stripe::BillingPortal::Configuration.list(active: true).data.find(&:is_default)
  end
end
