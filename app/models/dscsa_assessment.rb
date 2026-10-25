# A completed DSCSA readiness self-assessment. Public and pre-account --
# it's an acquisition funnel. Stores the answers, a 0-100 readiness score,
# and (optionally) who took it. `token` is the unguessable handle for the
# result page.
class DscsaAssessment < ApplicationRecord
  # The eight scored questions. `gap` is what a non-"yes" answer means, shown
  # back on the result page. Wording tracks the DSCSA enhanced drug
  # distribution security (EDDS) obligations that apply once the
  # small-dispenser exemption ends (2026-11-27); see the DSCSA blog post.
  QUESTIONS = [
    { key: "transaction_data",
      category: "Transaction data",
      prompt: "Can you receive and retain electronic, package-level transaction data (EPCIS / “T3”) from every wholesaler and distributor you buy from?",
      gap: "EDDS requires package-level transaction information, history, and statement for every product received, exchanged electronically with trading partners." },
    { key: "verification",
      category: "Product verification",
      prompt: "Can you verify a product identifier by scanning its 2D barcode, and trace an individual package rather than only a lot?",
      gap: "Dispensers must be able to verify product identifiers and respond to verification requests at the package level." },
    { key: "exceptions",
      category: "Exception handling",
      prompt: "Do you have a written process for suspect or illegitimate product — quarantine, investigation, and notifying the FDA and trading partners within 24 hours?",
      gap: "A documented suspect-product process with 24-hour notification is a standing DSCSA obligation, not a one-time task." },
    { key: "partners",
      category: "Trading partners",
      prompt: "Have you confirmed that every wholesaler and carrier you work with is a licensed, authorized trading partner — and do you re-check periodically?",
      gap: "You may only trade with authorized trading partners, and licensure status changes over time." },
    { key: "records",
      category: "Recordkeeping",
      prompt: "Are your transaction and custody records stored so you could produce any shipment’s full history quickly, and kept for at least six years?",
      gap: "DSCSA records must be retained about six years and be retrievable on request." },
    { key: "sops",
      category: "Written procedures",
      prompt: "Do you have current written SOPs for receiving, quarantine, recalls, and temperature excursions that your staff actually follow?",
      gap: "Inspectors expect documented, followed procedures — not institutional memory." },
    { key: "custody",
      category: "Chain of custody",
      prompt: "Do you have chain-of-custody documentation for products while they’re in transit between you and your trading partners?",
      gap: "Custody gaps in transit are where an audit trail most often breaks." },
    { key: "coldchain",
      category: "Cold chain",
      prompt: "For refrigerated products, do you have continuous temperature monitoring and a documented response when a shipment goes out of range?",
      gap: "A temperature excursion with no documented response is a finding waiting to happen." }
  ].freeze

  # A concrete first action per gap, for the downloadable readiness report
  # (DscsaReadinessReport) -- the result page explains what's missing, the
  # report is what a pharmacist prints and works through.
  NEXT_STEPS = {
    "transaction_data" => "Ask each wholesaler and distributor how they send package-level transaction data, and confirm you have a system (or their portal) that receives and keeps it for every product you receive.",
    "verification" => "Confirm your scanners read the 2D DataMatrix barcode, and write down how staff verify a product identifier when a trading partner or the FDA asks.",
    "exceptions" => "Write a one-page suspect-product procedure: quarantine, investigate, and notify the FDA (Form FDA 3911) and affected trading partners within 24 hours of determining a product is illegitimate.",
    "partners" => "List every wholesaler, distributor, and carrier you use, check each one's license, keep a dated record of the check, and put a recurring re-check on the calendar.",
    "records" => "Pick one recent shipment and time how long it takes to pull its full history. Set retention for transaction and custody records to at least six years.",
    "sops" => "Write or update SOPs for receiving, quarantine, recalls, and temperature excursions, and have every staff member sign that they've read them.",
    "custody" => "Record every handoff in transit — who, when, and where — with a signature at delivery, captured at the time rather than written up afterwards.",
    "coldchain" => "Monitor refrigerated shipments continuously, and write down what staff do when a reading leaves 2–8 °C: who is alerted, what happens to the product, and how it's documented."
  }.freeze

  # Gaps the platform closes directly; the rest are process and paperwork
  # for the compliance-officer retainer.
  PLATFORM_KEYS = %w[custody coldchain records].freeze

  # Asked for context, not scored: a "no" here means the exemption never
  # applied and the full requirements are already in force.
  CONTEXT_QUESTION = {
    key: "exemption",
    category: "Exemption status",
    prompt: "As of November 27, 2024, did your pharmacy employ 25 or fewer full-time licensed pharmacists and pharmacy technicians across all locations?"
  }.freeze

  ALL_KEYS = (QUESTIONS.map { |q| q[:key] } + [ CONTEXT_QUESTION[:key] ]).freeze
  ANSWERS  = %w[yes unsure no].freeze
  POINTS   = { "yes" => 2, "unsure" => 1, "no" => 0 }.freeze

  BAND_LABELS = {
    "significant_gaps" => "Significant gaps",
    "progressing"      => "Progressing",
    "nearly_ready"     => "Nearly ready",
    "well_positioned"  => "Well positioned",
    "unknown"          => "—"
  }.freeze

  before_validation :ensure_token, on: :create

  validates :token, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true, length: { maximum: 300 }
  validates :pharmacy_name, length: { maximum: 200 }

  # Build (not save) an assessment from flat request params -- question keys
  # map to "yes" / "unsure" / "no", anything else is treated as "unsure".
  def self.build_from(params)
    answers = ALL_KEYS.index_with do |key|
      value = params[key].to_s
      ANSWERS.include?(value) ? value : "unsure"
    end

    assessment = new(
      answers: answers,
      email: params[:email].to_s.strip.presence,
      pharmacy_name: params[:pharmacy_name].to_s.strip.presence
    )
    assessment.score = assessment.computed_score
    assessment.band  = assessment.computed_band
    assessment
  end

  def computed_score
    earned = QUESTIONS.sum { |q| POINTS.fetch(answers[q[:key]], 1) }
    ((earned.to_f / (QUESTIONS.size * 2)) * 100).round
  end

  def computed_band
    case score
    when 0..39  then "significant_gaps"
    when 40..69 then "progressing"
    when 70..89 then "nearly_ready"
    else "well_positioned"
    end
  end

  def band_label
    BAND_LABELS.fetch(band, band.to_s.humanize)
  end

  def gaps
    QUESTIONS.reject { |q| answers[q[:key]] == "yes" }
  end

  def strengths
    QUESTIONS.select { |q| answers[q[:key]] == "yes" }
  end

  def self.next_step_for(question)
    NEXT_STEPS.fetch(question[:key])
  end

  def self.closed_by_platform?(question)
    PLATFORM_KEYS.include?(question[:key])
  end

  # False = the exemption never applied, so the full requirements are
  # already in force (not "in force after 2026-11-27").
  def still_exempt?
    answers[CONTEXT_QUESTION[:key]] == "yes"
  end

  # Plain-text summary passed to a call request as context.
  def summary_for_call
    lines = [ "DSCSA readiness self-assessment: #{score}/100 (#{band_label})." ]
    lines << "Small-dispenser exemption still applies: #{still_exempt? ? 'yes' : 'no / unsure'}."
    lines << "Gaps flagged:"
    gaps.each { |q| lines << "  - #{q[:category]}: answered '#{answers[q[:key]]}'" }
    lines.join("\n")
  end

  def to_param
    token
  end

  private

  def ensure_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end
end
