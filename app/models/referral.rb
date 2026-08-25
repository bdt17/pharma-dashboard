# One row per referral relationship: a new organization signed up quoting
# an existing organization's referral_code. Reward (see ReferralReward) is
# only actually applied once the referred organization's subscription goes
# active for the first time -- not at signup -- so a code can't be farmed
# by creating accounts that never pay. rewarded_at nil means "earned, not
# yet paid out" or "not yet earned"; both look the same from here, since
# ReferralReward is the only thing that ever sets it.
class Referral < ApplicationRecord
  belongs_to :referrer_organization, class_name: "Organization"
  belongs_to :referred_organization, class_name: "Organization"

  validates :referred_organization_id, uniqueness: true

  scope :pending, -> { where(rewarded_at: nil) }
end
