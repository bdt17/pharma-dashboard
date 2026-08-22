# Shows the organization's real subscription state. There's no live Stripe
# checkout wired up yet (see StripeWebhooksController and the Phase 5 PR
# description for why) -- this reads what's actually in the database rather
# than rendering "Billing OK" or a fabricated "$500K ARR projection" the way
# the pages it replaces did.
class BillingController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscription = current_organization&.subscriptions&.order(created_at: :desc)&.first
  end
end
