module Ops
  # Gathers integration/config health into groups of checks for the /ops
  # page. Read-only -- no side effects, safe to call on every page load.
  # Each check is [label, status (:ok/:warn/:error), detail].
  class Diagnostics
    Check = Data.define(:label, :status, :detail)
    Group = Data.define(:name, :checks)

    def self.call
      new.groups
    end

    def groups
      [ email_group, billing_group, sms_group, webhooks_group, encryption_group, jobs_group, app_group, activity_group ]
    end

    private

    def sms_group
      sid   = ENV["TWILIO_ACCOUNT_SID"].present?
      token = ENV["TWILIO_AUTH_TOKEN"].present?
      from  = ENV["TWILIO_MESSAGING_FROM"].to_s
      configured = SmsSender.configured?
      recipients = AlertRecipient.active.count
      orgs = AlertRecipient.active.distinct.count(:organization_id)

      from_detail =
        if from.blank? then "unset -- excursion texts can't be sent"
        elsif from.start_with?("MG") then "set (Messaging Service)"
        else "set (sender number)"
        end

      Group.new(name: "SMS alerts (Twilio)", checks: [
        Check.new(label: "Overall",
                  status: configured ? :ok : :warn,
                  detail: configured ? "configured -- texts will send" : "not configured -- SMS excursion alerts are a silent no-op"),
        Check.new(label: "Account SID (TWILIO_ACCOUNT_SID)", status: sid ? :ok : :warn,
                  detail: sid ? "set" : "unset"),
        Check.new(label: "Auth token (TWILIO_AUTH_TOKEN)", status: token ? :ok : :warn,
                  detail: token ? "set" : "unset"),
        Check.new(label: "Sender (TWILIO_MESSAGING_FROM)", status: from.present? ? :ok : :warn,
                  detail: from_detail),
        Check.new(label: "Configured recipients", status: :ok,
                  detail: "#{recipients} active across #{orgs} organization#{'s' unless orgs == 1}")
      ])
    end

    def webhooks_group
      total    = WebhookEndpoint.count
      active   = WebhookEndpoint.active.count
      disabled = WebhookEndpoint.where(active: false).where("consecutive_failures >= ?", WebhookEndpoint::AUTO_DISABLE_AFTER).count
      failing  = WebhookEndpoint.active.where("consecutive_failures > 0").count

      Group.new(name: "Outbound webhooks", checks: [
        Check.new(label: "Endpoints", status: :ok,
                  detail: total.zero? ? "none registered" : "#{active} active of #{total}"),
        Check.new(label: "Auto-disabled (failed #{WebhookEndpoint::AUTO_DISABLE_AFTER}x)",
                  status: disabled.zero? ? :ok : :warn,
                  detail: disabled.to_s),
        Check.new(label: "Active endpoints currently failing",
                  status: failing.zero? ? :ok : :warn,
                  detail: failing.to_s)
      ])
    end

    def email_group
      postmark = ENV["POSTMARK_API_TOKEN"].present?
      smtp = ENV["SMTP_ADDRESS"].present?
      host = ENV["APP_HOST"].presence
      sender = ENV["MAILER_SENDER"].presence

      delivery_detail =
        if postmark then "Postmark API"
        elsif smtp then "SMTP via #{ENV['SMTP_ADDRESS']}"
        else "No POSTMARK_API_TOKEN or SMTP_ADDRESS -- mail is silently discarded (:test delivery)"
        end

      Group.new(name: "Email", checks: [
        Check.new(
          label: "Delivery method",
          status: (postmark || smtp) ? :ok : :error,
          detail: delivery_detail
        ),
        Check.new(
          label: "Sender address (MAILER_SENDER)",
          status: sender ? :ok : :warn,
          detail: sender || "unset -- defaults to no-reply@pharmatransport.org"
        ),
        Check.new(
          label: "Mail link host (APP_HOST)",
          status: host && host != "example.com" ? :ok : :error,
          detail: host.nil? ? "unset -- confirmation/reset links point at example.com" : host
        ),
        Check.new(
          label: "Leads inbox (LEADS_EMAIL)",
          status: ENV["LEADS_EMAIL"].present? ? :ok : :warn,
          detail: ENV["LEADS_EMAIL"].presence || "unset -- request-a-call notices go to the sender address"
        )
      ])
    end

    def billing_group
      key = Stripe.api_key.present?
      webhook = ENV["STRIPE_WEBHOOK_SECRET"].present?
      plans = key ? safe_plans : []
      tiers = plans.filter_map { |p| p[:tier] }.uniq
      last_sub = Subscription.order(updated_at: :desc).first

      Group.new(name: "Billing (Stripe)", checks: [
        Check.new(label: "Secret key (STRIPE_SECRET_KEY)", status: key ? :ok : :error,
                  detail: key ? "set" : "unset -- checkout and the pricing page can't reach Stripe"),
        Check.new(label: "Webhook secret (STRIPE_WEBHOOK_SECRET)", status: webhook ? :ok : :error,
                  detail: webhook ? "set" : "unset -- completed checkouts never sync; customers pay but stay on the free tier"),
        Check.new(label: "Subscription plans published",
                  status: tiers.sort == SubscriptionPlan.tiers.sort ? :ok : (key ? :warn : :error),
                  detail: key ? "tiers found: #{tiers.presence&.join(', ') || 'none'} (run stripe:sync_subscription_plans)" : "n/a until the key is set"),
        Check.new(label: "Subscriptions on file",
                  status: :ok,
                  detail: Subscription.group(:status).count.map { |s, n| "#{n} #{s}" }.join(", ").presence || "none yet"),
        Check.new(label: "Last subscription sync",
                  status: :ok,
                  detail: last_sub ? "#{last_sub.updated_at.iso8601} (#{last_sub.tier || 'no tier'})" : "never"),
        Check.new(label: "Overage billing",
                  status: :ok,
                  detail: overage_detail),
        Check.new(label: "Cards expiring soon",
                  status: cards_expiring.zero? ? :ok : :warn,
                  detail: "#{cards_expiring} organization#{'s' unless cards_expiring == 1} flagged")
      ])
    end

    def overage_detail
      opted_in = Organization.where(overage_billing_enabled: true).count
      overages = PacketOverage.this_month
      billed = overages.sum(:amount_cents) / 100.0

      "#{opted_in} org#{'s' unless opted_in == 1} opted in; " \
        "#{overages.count} extra packet#{'s' unless overages.count == 1} this month" \
        "#{" (#{ActiveSupport::NumberHelper.number_to_currency(billed)})" if overages.any?}"
    end

    def cards_expiring
      Organization.where.not(card_expiry_notified_for: nil).select(&:card_expiring_soon?).size
    end

    def encryption_group
      keys = %w[AR_ENCRYPTION_PRIMARY_KEY AR_ENCRYPTION_DETERMINISTIC_KEY AR_ENCRYPTION_KEY_DERIVATION_SALT]
      present = keys.count { |k| ENV[k].present? }
      unencrypted_ok = ActiveRecord::Encryption.config.support_unencrypted_data

      Group.new(name: "Encryption", checks: [
        Check.new(label: "AR_ENCRYPTION_* keys",
                  status: Rails.env.local? ? :ok : (present == 3 ? :ok : :error),
                  detail: Rails.env.local? ? "development fixed keys" : "#{present}/3 set"),
        Check.new(label: "support_unencrypted_data",
                  status: unencrypted_ok ? :warn : :ok,
                  detail: unencrypted_ok ? "on -- legacy plaintext still readable" : "off")
      ])
    end

    def jobs_group
      adapter = ActiveJob::Base.queue_adapter_name

      Group.new(name: "Background jobs", checks: [
        Check.new(label: "Queue adapter",
                  status: adapter == "async" ? :warn : :ok,
                  detail: adapter == "async" ? "async -- in-process, queued jobs are lost on restart (fine at low volume)" : adapter)
      ])
    end

    def app_group
      pending = begin
        ActiveRecord::Migration.check_all_pending!
        false
      rescue ActiveRecord::PendingMigrationError
        true
      end

      sentry_configured = ENV["SENTRY_DSN"].present?
      ads_id = ENV["GOOGLE_ADS_CONVERSION_ID"].present?
      ads_labels = ConversionTrackingHelper::CONVERSION_EVENTS.count { |_, var| ENV[var].present? }

      Group.new(name: "Application", checks: [
        Check.new(label: "Environment", status: :ok, detail: Rails.env),
        Check.new(label: "Deployed revision",
                  status: :ok,
                  detail: (ENV["RENDER_GIT_COMMIT"] || ENV["GIT_COMMIT"]).to_s[0, 12].presence || "unknown"),
        Check.new(label: "Ruby / Rails", status: :ok, detail: "#{RUBY_VERSION} / #{Rails.version}"),
        Check.new(label: "Pending migrations", status: pending ? :error : :ok, detail: pending ? "yes -- deploy is out of sync" : "none"),
        Check.new(label: "Server time", status: :ok, detail: Time.current.iso8601),
        Check.new(label: "Error tracking (SENTRY_DSN)",
                  status: sentry_configured ? :ok : :warn,
                  detail: sentry_configured ? "configured" : "unset -- unhandled exceptions and rescued failures aren't reported anywhere"),
        Check.new(label: "Google Ads conversion tracking (GOOGLE_ADS_CONVERSION_ID)",
                  status: ads_id ? :ok : :warn,
                  detail: ads_id ? "configured -- #{ads_labels}/#{ConversionTrackingHelper::CONVERSION_EVENTS.size} conversion events labelled" : "unset -- paid campaigns can't measure sign-ups")
      ])
    end

    def activity_group
      Group.new(name: "Recent activity", checks: [
        Check.new(label: "Organizations / users", status: :ok, detail: "#{Organization.count} / #{User.count}"),
        Check.new(label: "Unhandled call requests", status: CallRequest.unhandled.any? ? :warn : :ok,
                  detail: CallRequest.unhandled.count.to_s),
        Check.new(label: "DSCSA assessments (7d)", status: :ok,
                  detail: DscsaAssessment.where(created_at: 7.days.ago..).count.to_s),
        Check.new(label: "Acquisition sources (7d)", status: :ok, detail: acquisition_detail),
        Check.new(label: "Compliance packets (30d)", status: :ok,
                  detail: ComplianceReport.where(created_at: 30.days.ago..).count.to_s)
      ])
    end

    # Breaks down the last 7 days of DSCSA assessments (the funnel Ads
    # money is meant to point at) by first-touch UTM source/campaign --
    # see UtmTracking. The point is a cheap read on whether a given
    # campaign is bringing anyone in at all before spending more on it,
    # not a full analytics view.
    def acquisition_detail
      assessments = DscsaAssessment.where(created_at: 7.days.ago..)
      return "no assessments yet" if assessments.none?

      top = assessments.group(:utm_source, :utm_campaign).count.sort_by { |_, count| -count }.first(3)
      summary = top.map { |(source, campaign), count| "#{acquisition_label(source, campaign)}: #{count}" }.join(", ")
      "#{assessments.count} total -- #{summary}"
    end

    def acquisition_label(source, campaign)
      [ source, campaign ].compact.presence&.join("/") || "direct/unknown"
    end

    def safe_plans
      StripeBilling.available_plans
    rescue Stripe::StripeError => e
      Rails.logger.warn("Ops::Diagnostics: Stripe plan lookup failed (#{e.class})")
      []
    end
  end
end
