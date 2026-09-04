# Public marketing pages that aren't the homepage and aren't a blog post --
# Pricing today, About to follow. Separate from HomeController (which is
# mostly auth-state redirects) and BlogController (post-specific actions)
# since this is where general public-facing company pages belong.
class PagesController < ApplicationController
  # Reuses the exact same live-Stripe-data path BillingController uses for
  # signed-in users (StripeBilling.available_plans) -- pricing shown here is
  # never a hardcoded/guessed number, it's whatever is actually configured
  # as an active Price in Stripe right now.
  def pricing
    @plans = StripeBilling.available_plans
  end

  # Paid-search / content landing page for "small pharmacy DSCSA 2026" and
  # similar terms. Deliberately separate from #pricing: a cold visitor
  # from an ad has none of the context a pricing page assumes, and the
  # highest-converting first step for that traffic is the free readiness
  # check, not a plan comparison.
  def dscsa_2026
    # Same "read Stripe, don't hardcode" rule as #pricing -- a stale
    # hardcoded number on an ad landing page is exactly the kind of thing
    # that quietly drifts wrong after a price change and undersells (or
    # oversells) the offer the ad promised.
    starter_price = StripeBilling.available_plans.find { |p| p[:tier] == "starter" && p[:interval] == "month" }
    @starter_monthly = starter_price ? starter_price[:amount].to_i : SubscriptionPlan::STARTER.monthly_dollars
  end

  def about
  end

  # Public security & compliance overview -- a plain account of how the
  # custody record's integrity is protected, how the app is built, and which
  # frameworks the design is aligned to (including what is not yet claimed).
  # Prospects in regulated pharma ask for this before they'll evaluate.
  def security
  end

  # Pitch page for the fractional-compliance-officer retainer -- a services
  # offering alongside the subscription. The CTA is an intro call, not
  # self-serve checkout, so there's no Stripe/plan data to load.
  def compliance_officer
  end
end
