# The downloadable PDF version of a DSCSA readiness self-assessment: the
# score, every gap with what the requirement is and a concrete first step,
# and what's already in place. The result page is read once; this is what
# gets printed, handed to the pharmacist-in-charge, and worked through --
# and every copy that gets passed around carries the link back.
class DscsaReadinessReport
  BRAND = "1f3a53".freeze
  MUTED = "5b6b7c".freeze
  BAND_COLORS = {
    "significant_gaps" => "b42318",
    "progressing"      => "b45309",
    "nearly_ready"     => "0f766e",
    "well_positioned"  => "0f766e"
  }.freeze
  ANSWER_LABELS = { "no" => "No", "unsure" => "Not sure" }.freeze

  def initialize(assessment, result_url:)
    @assessment = assessment
    @result_url = result_url
  end

  def generate
    pdf = Prawn::Document.new(page_size: "LETTER", margin: 54, info: { Title: "DSCSA Readiness Report", Creator: "Pharma Transport" })

    header(pdf)
    score(pdf)
    action_plan(pdf)
    strengths(pdf)
    closing(pdf)
    page_footers(pdf)

    pdf.render
  end

  def filename
    name = assessment.pharmacy_name.to_s.parameterize.presence
    [ "dscsa-readiness", name, assessment.created_at.to_date.iso8601 ].compact.join("-") + ".pdf"
  end

  private

  attr_reader :assessment, :result_url

  def header(pdf)
    pdf.fill_color BRAND
    pdf.text "DSCSA Readiness Report", size: 22, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 2
    pdf.text assessment.pharmacy_name.presence || "Self-assessment", size: 13
    pdf.text "Completed #{assessment.created_at.strftime('%B %-d, %Y')}", size: 9, color: MUTED
    pdf.move_down 14
    pdf.stroke_color "d5dce3"
    pdf.stroke_horizontal_rule
    pdf.move_down 16
  end

  def score(pdf)
    color = BAND_COLORS.fetch(assessment.band, MUTED)
    pdf.formatted_text [
      { text: assessment.score.to_s, size: 40, styles: [ :bold ], color: color },
      { text: " / 100   ", size: 14, color: MUTED },
      { text: assessment.band_label, size: 14, styles: [ :bold ], color: color }
    ]
    pdf.move_down 8
    pdf.text deadline_line, size: 10.5, leading: 2
    pdf.move_down 20
  end

  def deadline_line
    unless assessment.still_exempt?
      return "You indicated the small-dispenser exemption may not apply to your pharmacy. " \
             "If so, the enhanced requirements below are already in force, not pending."
    end

    if DscsaDeadline.passed?
      "The DSCSA small-dispenser exemption ended on #{DscsaDeadline.label}. " \
        "The requirements below apply now."
    else
      days = DscsaDeadline.days_left
      left = days.zero? ? "today is the last day" : "#{days} #{'day'.pluralize(days)} from today"
      "The DSCSA small-dispenser exemption ends on #{DscsaDeadline.label} (#{left}). " \
        "After that, the requirements below apply."
    end
  end

  def action_plan(pdf)
    gaps = assessment.gaps
    section_heading(pdf, gaps.any? ? "Your action plan: #{gaps.size} of #{DscsaAssessment::QUESTIONS.size} areas to close" : "Your action plan")

    if gaps.empty?
      pdf.text "You answered every question \"yes\". On paper you're ready. Before relying on that, " \
               "check any answer that was a best guess rather than something you could show an inspector.",
               size: 10.5, leading: 2
      pdf.move_down 18
      return
    end

    if gaps.any? { |q| assessment.answers[q[:key]] == "unsure" }
      pdf.text "\"Not sure\" counts as a gap until you can confirm it — an inspector will ask for evidence, not intent.",
               size: 9, color: MUTED, style: :italic
      pdf.move_down 10
    end

    gaps.each_with_index { |q, i| gap_item(pdf, q, i + 1) }
  end

  # Keeps an item off a page break. Document#group, the Prawn way to do
  # this, is disabled in Prawn 2.5 (it corrupted documents).
  def keep_together(pdf, height)
    pdf.start_new_page if pdf.cursor < height
  end

  def gap_item(pdf, question, number)
    keep_together(pdf, 150)
    pdf.formatted_text [
      { text: "#{number}. #{question[:category]}", size: 12, styles: [ :bold ] },
      { text: "   You answered \"#{ANSWER_LABELS.fetch(assessment.answers[question[:key]], 'Not sure')}\"", size: 9, color: MUTED }
    ]
    pdf.move_down 4
    labelled(pdf, "Requirement", question[:gap])
    labelled(pdf, "First step", DscsaAssessment.next_step_for(question))
    labelled(pdf, "Who closes it", DscsaAssessment.closed_by_platform?(question) ?
      "Software. Pharma Transport records this automatically for every shipment." :
      "Process and paperwork. Your team, or a fractional compliance officer.")
    pdf.text "[  ] Done      Owner: ____________________      Target date: ____________", size: 9, color: MUTED
    pdf.move_down 14
  end

  def labelled(pdf, label, body)
    pdf.formatted_text [ { text: "#{label}: ", styles: [ :bold ] }, { text: body } ], size: 10, leading: 2
    pdf.move_down 4
  end

  def strengths(pdf)
    return if assessment.strengths.empty?

    section_heading(pdf, "Already in place")
    pdf.text assessment.strengths.map { |q| q[:category] }.join("  |  "), size: 10.5
    pdf.move_down 20
  end

  def closing(pdf)
    keep_together(pdf, 130)
    section_heading(pdf, "Closing the gaps")
    pdf.text "Pharma Transport handles chain of custody, cold-chain monitoring, and six-year retrievable records " \
             "for every shipment, with a #{StripeBilling::TRIAL_PERIOD_DAYS}-day free trial. For SOPs, trading-partner " \
             "checks, and the suspect-product process, a fractional compliance officer can own the work.",
             size: 10.5, leading: 2
    pdf.move_down 8
    if DeadlineOffer.active?
      pdf.text "Start a free trial before #{DscsaDeadline.label} and we'll set up your account with you for free " \
               "(#{DeadlineOffer.value_label} value).", size: 10.5, style: :bold, leading: 2
      pdf.move_down 8
    end
    pdf.formatted_text [
      { text: "Your full results: ", styles: [ :bold ] },
      { text: result_url, link: result_url, color: BRAND }
    ], size: 10
    pdf.formatted_text [
      { text: "Talk it through: ", styles: [ :bold ] },
      { text: "pharmatransport.org/request-a-call", link: "https://pharmatransport.org/request-a-call", color: BRAND }
    ], size: 10
  end

  def section_heading(pdf, title)
    pdf.fill_color BRAND
    pdf.text title, size: 14, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 8
  end

  def page_footers(pdf)
    pdf.repeat(:all, dynamic: true) do
      pdf.bounding_box([ pdf.bounds.left, pdf.bounds.bottom - 14 ], width: pdf.bounds.width, height: 24) do
        pdf.text "Informational self-assessment, not a compliance determination or legal advice. Confirm current " \
                 "requirements against FDA DSCSA guidance or with counsel.   Page #{pdf.page_number} of #{pdf.page_count}",
                 size: 7.5, color: "8a96a3"
      end
    end
  end
end
