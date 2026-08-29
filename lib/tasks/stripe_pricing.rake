namespace :stripe do
  desc "Ensure the Starter / Pro / Compliance subscription Products + monthly Prices exist (safe to re-run)"
  task sync_subscription_plans: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    result = StripeSubscriptionPlansSync.call
    result.existing.each { |price| puts "Already present: #{price.id}" }
    result.created.each { |price| puts "Created #{price.id} (#{price.unit_amount / 100.0} #{price.currency}/month)" }
    puts "Now run stripe:sync_annual_prices to create the 10%-off annual variants." if result.created.any?
  end

  desc "Ensure every active monthly Stripe Price has a matching annual Price at 10% off (safe to re-run)"
  task sync_annual_prices: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    result = StripeAnnualPriceSync.call
    if result.created.empty?
      puts "Every monthly plan already has an annual price. Nothing to do."
    else
      result.created.each { |price| puts "Created annual price #{price.id} (#{price.unit_amount / 100.0} #{price.currency}/year)" }
    end
  end

  desc "Ensure the one-time 'Extra Compliance Packet' ($149) Stripe price exists (safe to re-run)"
  task sync_addon_prices: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    price = StripeAddonPriceSync.call
    puts "Extra Compliance Packet price: #{price.id} (#{price.unit_amount / 100.0} #{price.currency})"
  end

  desc "Ensure the reusable 'referral free month' Stripe coupon exists (safe to re-run)"
  task sync_referral_coupon: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    coupon = StripeReferralCouponSync.call
    puts "Referral coupon: #{coupon.id} (#{coupon.percent_off}% off, #{coupon.duration})"
  end

  desc "Ensure the one-time '10 Extra Compliance Packets' bulk-pack Stripe price exists (safe to re-run)"
  task sync_bulk_addon_prices: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    price = StripeBulkAddonPriceSync.call
    puts "10-pack Compliance Packet price: #{price.id} (#{price.unit_amount / 100.0} #{price.currency})"
  end

  desc "Ensure the one-time 'White-Glove Setup' ($299) Stripe price exists (safe to re-run)"
  task sync_white_glove_setup_price: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    price = StripeWhiteGloveSetupPriceSync.call
    puts "White-Glove Setup price: #{price.id} (#{price.unit_amount / 100.0} #{price.currency})"
  end

  desc "Ensure a default Stripe Billing Portal configuration exists (safe to re-run)"
  task sync_billing_portal_config: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    config = StripeBillingPortalConfigSync.call
    puts "Billing Portal configuration: #{config.id}"
  end

  desc "Ensure the 'founding customer' launch-offer Stripe coupon exists (safe to re-run)"
  task sync_founding_coupon: :environment do
    unless StripeBilling.configured?
      puts "STRIPE_SECRET_KEY isn't set -- nothing to do."
      next
    end

    coupon = StripeFoundingCouponSync.call
    puts "Founding customer coupon: #{coupon.id} (#{coupon.percent_off}% off, #{coupon.duration_in_months} months, redeem by #{Time.at(coupon.redeem_by).utc})"
  end
end
