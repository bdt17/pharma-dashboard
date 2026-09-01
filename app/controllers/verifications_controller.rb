# Public, unauthenticated page a subscribed pharmacy can link to from
# their own website (or hand to an auditor) as evidence they're actively
# using Pharma Transport for chain-of-custody/compliance tracking -- not
# itself a billable feature, but makes subscribing something concrete to
# point to, which supports the sales/outreach side of things rather than
# charging directly. See Organization#verified? for what "verified" means
# here, and Organization#verification_token for the unguessable lookup key
# (deliberately not the numeric id or anything else guessable).
class VerificationsController < ApplicationController
  def show
    @organization = Organization.find_by!(verification_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render "not_found", status: :not_found
  end

  # The SVG the "Share Pharma Transport" snippet on the Billing page embeds.
  # Served to anyone -- it's on the customer's public site. Cached for an
  # hour so a busy page doesn't hammer this on every load; the badge only
  # flips when a subscription starts or lapses, which the customer isn't
  # watching by the minute.
  def badge
    organization = Organization.find_by(verification_token: params[:token])
    return head :not_found unless organization

    expires_in 1.hour, public: true
    render plain: VerificationBadge.new(organization).svg, content_type: "image/svg+xml"
  end
end
