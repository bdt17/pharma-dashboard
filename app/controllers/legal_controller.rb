# Static Terms of Service / Privacy Policy pages. No prior version of
# either existed anywhere in the app -- Stripe requires a live account to
# link its terms during Checkout, and a real customer evaluating
# compliance-adjacent software (chain-of-custody, FDA audit trail) has
# nothing to point to without these. First-draft content: written from
# what the app actually does and collects, not boilerplate, but it's a
# starting point for the business owner (and ideally counsel) to review
# and adjust before it's relied on with real paying customers.
class LegalController < ApplicationController
  def terms
  end

  def privacy
  end
end
