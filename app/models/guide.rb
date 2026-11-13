# The plain-language DSCSA guides under /guides: one entry per page, in
# the order the index lists them. Each page's body lives in
# app/views/guides/<slug>.html.erb; this registry holds what the index,
# the sitemap and the page head need.
#
# Every factual claim in the guides was checked against FD&C Act
# sections 581-582 and FDA's 2026-08-06 small-dispenser exemption notice
# on REVIEWED_ON. Re-check them, and bump REVIEWED_ON, before changing
# any. Dates come from DscsaDeadline so nothing goes stale.
class Guide
  REVIEWED_ON = Date.new(2026, 11, 13)

  Entry = Data.define(:slug, :title, :summary)

  ALL = [
    Entry.new(slug: "dscsa-compounding-pharmacies", title: "DSCSA for compounding pharmacies",
              summary: "What DSCSA covers when you compound, and what it doesn't."),
    Entry.new(slug: "dscsa-long-term-care-pharmacies", title: "DSCSA for long-term care pharmacies",
              summary: "Facility deliveries, pharmacy-to-pharmacy sales, and the headcount question for multi-site groups."),
    Entry.new(slug: "dscsa-specialty-pharmacies", title: "DSCSA for specialty pharmacies",
              summary: "High-value, cold-chain product and the obligations that apply today."),
    Entry.new(slug: "dscsa-pharmacy-delivery", title: "DSCSA and pharmacy delivery",
              summary: "Why delivery to a patient isn't a DSCSA transaction, and what delivery records are for."),
    Entry.new(slug: "dscsa-transaction-information-statement", title: "Transaction information, statements, and the end of transaction history",
              summary: "What \"T3\" means now, what you must keep, and for how long."),
    Entry.new(slug: "dscsa-suspect-illegitimate-product", title: "Handling suspect and illegitimate product",
              summary: "Quarantine, investigation, and the 24-hour notice, step by step.")
  ].freeze

  SLUGS = ALL.map(&:slug).freeze

  def self.find(slug) = ALL.find { |entry| entry.slug == slug }
end
