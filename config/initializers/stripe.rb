# Stripe::Webhook.construct_event (StripeWebhooksController) doesn't need
# Stripe.api_key set -- signature verification is local. Everything else
# that calls the Stripe API (listing plans, creating a checkout session)
# does, and simply won't work until STRIPE_SECRET_KEY is set in the
# environment. That's intentional: no live-mode key means no live charges,
# by construction, not by remembering to flip a flag somewhere.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
