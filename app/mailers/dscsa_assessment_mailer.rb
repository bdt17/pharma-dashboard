# The DSCSA readiness assessment (see DscsaAssessment) is a lead-gen
# funnel with no account behind it -- this is the only thing that keeps
# talking to someone after they close the result tab. Three sends,
# scheduled by DscsaAssessmentsController#create at submission time:
#   1. result_email      -- immediate, the score they asked for
#   2. follow_up_day3     -- +3 days, one specific gap
#   3. follow_up_day7     -- +7 days, broader nurture + urgency
# DscsaAssessmentFollowUpJob re-checks EmailSuppression and whether the
# email has already converted right before each of the two delayed sends
# -- this mailer itself doesn't guard against either, since by the time
# it's called that decision has already been made.
class DscsaAssessmentMailer < ApplicationMailer
  def result_email(assessment)
    @assessment = assessment
    @unsubscribe_url = unsubscribe_url_for(assessment.email)

    mail(to: assessment.email, subject: "Your DSCSA readiness score: #{assessment.score}/100")
  end

  def follow_up_day3(assessment)
    @assessment = assessment
    @gap = priority_gap(assessment)
    @platform_solved = DscsaAssessment.closed_by_platform?(@gap)
    @unsubscribe_url = unsubscribe_url_for(assessment.email)

    mail(to: assessment.email, subject: "Closing the #{@gap[:category].downcase} gap")
  end

  def follow_up_day7(assessment)
    @assessment = assessment
    @unsubscribe_url = unsubscribe_url_for(assessment.email)

    mail(to: assessment.email, subject: "Still on your DSCSA to-do list?")
  end

  private

  # Also sets the RFC 8058 one-click headers, so mail clients show their
  # own "Unsubscribe" button (Gmail/Yahoo bulk-sender requirement) that
  # POSTs straight to /unsubscribe.
  def unsubscribe_url_for(email)
    url = unsubscribe_url(token: EmailUnsubscribeToken.generate(email))
    headers["List-Unsubscribe"] = "<#{url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    url
  end

  # The gap to lead with in the day-3 email: prefer one the platform
  # itself closes (a trial converts directly) over one that needs a
  # written process or the compliance-officer retainer. Falls back to
  # whatever gap is first if every gap is platform-solvable or none are.
  def priority_gap(assessment)
    gaps = assessment.gaps
    gaps.find { |g| DscsaAssessment.closed_by_platform?(g) } || gaps.first
  end
end
