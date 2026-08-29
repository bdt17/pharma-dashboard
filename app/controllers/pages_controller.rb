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
