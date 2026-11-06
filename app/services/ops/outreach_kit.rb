module Ops
  # Everything the operator needs to send outreach from /ops/outreach:
  # campaign-tagged links into the funnel, and ready-to-send messages that
  # carry those links. Every date comes from DscsaDeadline / DeadlineOffer,
  # so nothing here goes stale on 2026-11-28 or 2027-01-01 -- the
  # free-setup lines drop out on their own once the offer ends.
  #
  # Tagged links feed UtmTracking's first-touch cookie, which stamps the
  # readiness check, call request or new org -- see Ops::CampaignFunnel.
  class OutreachKit
    SOURCES = %w[linkedin email association partner referral].freeze

    # key => [label, route helper]
    LANDING_PAGES = {
      "assessment" => [ "Readiness check", :dscsa_assessment_url ],
      "independent_pharmacy" => [ "Independent pharmacy page", :independent_pharmacy_url ],
      "dscsa_2026" => [ "DSCSA extension page", :dscsa_2026_url ],
      "signup" => [ "Start a trial", :new_user_registration_url ]
    }.freeze

    Template = Data.define(:key, :title, :when_to_use, :subject, :body, :link)

    def self.campaign_slug(value)
      value.to_s.downcase.strip.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "").first(UtmTracking::MAX_LENGTH)
    end

    # Defaults to the mailer's host and protocol: these links go out in
    # email, same as every other link the app mails.
    def initialize(url_options: Rails.application.config.action_mailer.default_url_options || {})
      @url_options = url_options.to_h.symbolize_keys
    end

    def link(page:, source:, campaign:)
      helper = LANDING_PAGES.fetch(page.to_s) { LANDING_PAGES.fetch("assessment") }.last
      params = { utm_source: SOURCES.include?(source.to_s) ? source.to_s : SOURCES.first,
                 utm_campaign: self.class.campaign_slug(campaign).presence }.compact
      routes.public_send(helper, **@url_options, **params)
    end

    def templates
      [ association, linkedin_connect, linkedin_first_message, cold_email, follow_up ]
        .map { |template| template.with(body: template.body.gsub(/[ \t]+$/, "").gsub(/\n{3,}/, "\n\n").strip) }
    end

    private

    def routes = Rails.application.routes.url_helpers

    def deadline = DscsaDeadline.label
    def qualifying = DscsaDeadline.qualifying_label

    def offer_line(prefix = "")
      return "" unless DeadlineOffer.active?

      "#{prefix}If you start a trial before #{DeadlineOffer.label}, we set the whole thing up with you " \
        "on a call at no charge (normally #{DeadlineOffer.value_label})."
    end

    def status_paragraph
      if DscsaDeadline.passed?
        "The small-dispenser exemption ended on #{deadline}, so the package-level tracing requirements apply now."
      else
        "The FDA extended the small-dispenser exemption to #{deadline}, and whether a pharmacy qualifies is " \
          "based on its headcount as of #{qualifying}. The extension only delays the package-level tracing " \
          "requirements. Buying only from authorized trading partners, a process for suspect product, and " \
          "six years of transaction records all apply today."
      end
    end

    def association
      link = link(page: "assessment", source: "association", campaign: "member-webinar")
      Template.new(
        key: "association", title: "State pharmacy association: free member webinar",
        when_to_use: "To the executive director of a state pharmacists or independent pharmacy association, or NCPA.",
        subject: DscsaDeadline.passed? ? "Free member webinar: DSCSA compliance for small pharmacies" :
                                         "Free member webinar: the DSCSA extension and what small pharmacies should do this year",
        body: <<~TEXT, link: link)
          Hi [First name],

          I run Pharma Transport, a DSCSA compliance and delivery-records platform for independent pharmacies. I'd like to offer [Association] members a free 30-minute webinar, educational and not a sales pitch.

          #{status_paragraph} Most of the owners I talk to aren't sure which parts apply to them yet.

          The session would cover:
          - who qualifies for the small-dispenser exemption, and what it does and doesn't cover
          - what's required today, and what changes on #{deadline}
          - a practical checklist a pharmacist-in-charge can work through this year

          Members can also take our free 2-minute readiness check beforehand to see where they stand:
          #{link}

          Would a date in the next few weeks work for your members? I'm happy to fit your newsletter or meeting format.

          Thanks,
          Brett Thomas
          Pharma Transport · pharmatransport.org
        TEXT
    end

    def linkedin_connect
      Template.new(
        key: "linkedin_connect", title: "LinkedIn connection note",
        when_to_use: "The note on a connection request. 300 characters max, no link.",
        subject: nil, link: nil,
        body: "Hi [First name] -- I build DSCSA compliance software for independent pharmacies. " \
              "#{DscsaDeadline.passed? ? 'With the small-dispenser exemption now over' : "With the exemption pushed to #{DscsaDeadline::DATE.year}"}, " \
              "I've been talking to owners about where they stand. Would value connecting.")
    end

    def linkedin_first_message
      link = link(page: "assessment", source: "linkedin", campaign: "first-message")
      Template.new(
        key: "linkedin_first_message", title: "LinkedIn first message",
        when_to_use: "After they accept. One ask, no demo request.",
        subject: nil, link: link,
        body: <<~TEXT)
          Thanks for connecting, [First name]. Quick one: has [Pharmacy] looked at what DSCSA means for you #{DscsaDeadline.passed? ? 'now that the exemption has ended' : 'since the extension'}? #{DscsaDeadline.passed? ? '' : "Qualifying is based on headcount as of #{qualifying}, and the exemption doesn't cover everything. "}We made a free 2-minute readiness check that lays out exactly what applies:
          #{link}

          Happy to walk through your results if it's useful. No pressure either way.#{offer_line(' ')}
        TEXT
    end

    def cold_email
      link = link(page: "independent_pharmacy", source: "email", campaign: "cold-independent")
      assessment = link(page: "assessment", source: "email", campaign: "cold-independent")
      Template.new(
        key: "cold_email", title: "Cold email to an independent pharmacy",
        when_to_use: "First email to an owner or PIC. Personalize the first line from the prospect sheet's hook.",
        subject: DscsaDeadline.passed? ? "[Pharmacy] and DSCSA" : "[Pharmacy] and the DSCSA extension",
        link: link, body: <<~TEXT)
          Hi [First name],

          [One line about their pharmacy: delivery, LTC, compounding, years in the community.]

          #{status_paragraph}

          We built Pharma Transport for pharmacies your size: signed pickup and delivery records from the driver's phone (with GPS and temperature), DSCSA documentation packets, and an audit trail an inspector can read. It also gives you proof of the care mail-order can't match:
          #{link}

          If you'd rather start with where you stand, the free readiness check takes 2 minutes:
          #{assessment}
          #{offer_line("\n")}

          Brett Thomas
          Pharma Transport · pharmatransport.org
        TEXT
    end

    def follow_up
      link = link(page: "assessment", source: "email", campaign: "follow-up")
      Template.new(
        key: "follow_up", title: "Follow-up (once, after 5 business days)",
        when_to_use: "Reply on the same thread if there was no answer. Then stop.",
        subject: nil, link: link, body: <<~TEXT)
          Hi [First name], just floating this back up once. If DSCSA isn't on your list right now, no problem.

          If it is, the 2-minute readiness check gives you a printable action plan you can hand to your PIC:
          #{link}
          #{offer_line("\n")}

          Brett
        TEXT
    end
  end
end
