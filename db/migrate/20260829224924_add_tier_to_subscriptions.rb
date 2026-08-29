class AddTierToSubscriptions < ActiveRecord::Migration[8.1]
  # Which plan an active subscription is on -- "starter" / "pro" /
  # "compliance", read from the Stripe Price's `tier` metadata by the
  # webhook. Nullable: a subscription created before tiers existed, or one
  # whose Price carries no `tier` metadata, has no tier and is treated as
  # unlimited (the pre-tier behaviour) by ComplianceReportQuota.
  def change
    add_column :subscriptions, :tier, :string
  end
end
