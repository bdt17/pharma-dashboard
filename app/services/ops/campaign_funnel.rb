module Ops
  # The acquisition funnel on /ops/outreach, one row per first-touch
  # utm_source/utm_campaign pair (see UtmTracking): readiness checks ->
  # left an email -> downloaded the PDF action plan -> asked for a call ->
  # signed up -> trialing or paying. The point is telling which outreach
  # channel brings in anyone at all, so rows are counts, not rates.
  #
  # Signups and subscriptions are customer orgs only (Organization.customers);
  # an org's row comes from the attribution stamped on it at signup. Records
  # with no utm at all land in a single "direct" row. Read-only.
  class CampaignFunnel
    WINDOWS = { "30" => 30.days, "90" => 90.days, "all" => nil }.freeze
    DEFAULT_WINDOW = "30".freeze

    Row = Data.define(:source, :campaign, :checks, :emails, :pdfs, :calls, :signups, :converted) do
      def label = source || campaign ? [ source || "(no source)", campaign ].compact.join(" / ") : "direct"
    end

    attr_reader :window

    def initialize(window: DEFAULT_WINDOW, now: Time.current)
      @window = WINDOWS.key?(window.to_s) ? window.to_s : DEFAULT_WINDOW
      @since = WINDOWS[@window]&.then { |period| now - period }
    end

    def rows
      @rows ||= begin
        keys = [ checks, emails, pdfs, calls, signups, converted ].flat_map(&:keys).uniq
        keys.map do |key|
          Row.new(source: key[0], campaign: key[1], checks: checks[key].to_i, emails: emails[key].to_i,
                  pdfs: pdfs[key].to_i, calls: calls[key].to_i, signups: signups[key].to_i,
                  converted: converted[key].to_i)
        end.sort_by { |row| [ -row.signups, -row.calls, -row.checks, row.label ] }
      end
    end

    def totals
      Row.new(source: nil, campaign: nil, **%i[checks emails pdfs calls signups converted].index_with { |col| rows.sum(&col) })
    end

    private

    def scoped(relation)
      @since ? relation.where(created_at: @since..) : relation
    end

    def grouped(relation)
      relation.group(:utm_source, :utm_campaign).count
    end

    def assessments = scoped(DscsaAssessment.all)

    def checks = @checks ||= grouped(assessments)
    def emails = @emails ||= grouped(assessments.where.not(email: [ nil, "" ]))
    def pdfs = @pdfs ||= grouped(assessments.where.not(report_downloaded_at: nil))
    def calls = @calls ||= grouped(scoped(CallRequest.all))

    def signups
      @signups ||= grouped(scoped(Organization.customers))
    end

    def converted
      @converted ||= grouped(scoped(Organization.customers)
        .where(id: Subscription.where(status: %w[trialing active]).select(:organization_id)))
    end
  end
end
