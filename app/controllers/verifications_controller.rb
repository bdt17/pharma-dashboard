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
end
