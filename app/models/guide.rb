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

  # summary is the one-line teaser on the index; description is the
  # longer search-result / link-preview text (aim for 120-160 chars).
  Entry = Data.define(:slug, :title, :summary, :description)

  ALL = [
    Entry.new(slug: "dscsa-compounding-pharmacies", title: "DSCSA for compounding pharmacies",
              summary: "What DSCSA covers when you compound, and what it doesn't.",
              description: "Compounded 503A and 503B drugs aren't DSCSA \"product\", but the commercial drugs you buy and stock are. What applies to compounding pharmacies today."),
    Entry.new(slug: "dscsa-long-term-care-pharmacies", title: "DSCSA for long-term care pharmacies",
              summary: "Facility deliveries, pharmacy-to-pharmacy sales, and the headcount question for multi-site groups.",
              description: "DSCSA for long-term care pharmacies: facility deliveries, pharmacy-to-pharmacy sales, and how multi-site groups count staff for the small-dispenser exemption."),
    Entry.new(slug: "dscsa-specialty-pharmacies", title: "DSCSA for specialty pharmacies",
              summary: "High-value, cold-chain product and the obligations that apply today.",
              description: "DSCSA for specialty pharmacies handling high-value and cold-chain product: authorized partners, transaction records, and suspect-product duties that apply now."),
    Entry.new(slug: "dscsa-pharmacy-delivery", title: "DSCSA and pharmacy delivery",
              summary: "Why delivery to a patient isn't a DSCSA transaction, and what delivery records are for.",
              description: "Delivering to a patient isn't a DSCSA transaction. What pharmacy delivery records are still for, and what a clean chain-of-custody record looks like."),
    Entry.new(slug: "dscsa-transaction-information-statement", title: "Transaction information, statements, and the end of transaction history",
              summary: "What \"T3\" means now, what you must keep, and for how long.",
              description: "Transaction history ended in 2023. What pharmacies must still receive and keep: transaction information and statements, held at least six years."),
    Entry.new(slug: "dscsa-suspect-illegitimate-product", title: "Handling suspect and illegitimate product",
              summary: "Quarantine, investigation, and the 24-hour notice, step by step.",
              description: "How a pharmacy handles suspect and illegitimate drug product under DSCSA: quarantine, investigation, and the 24-hour notice to FDA (Form 3911) and partners.")
  ].freeze

  SLUGS = ALL.map(&:slug).freeze

  def self.find(slug) = ALL.find { |entry| entry.slug == slug }
end
