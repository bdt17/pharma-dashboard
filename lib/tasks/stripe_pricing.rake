namespace :stripe do
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
end
