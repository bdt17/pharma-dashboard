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
    @platform_solved = PLATFORM_SOLVED_KEYS.include?(@gap[:key])
    @unsubscribe_url = unsubscribe_url_for(assessment.email)

    mail(to: assessment.email, subject: "Closing the #{@gap[:category].downcase} gap before Nov 27")
  end

  def follow_up_day7(assessment)
    @assessment = assessment
    @unsubscribe_url = unsubscribe_url_for(assessment.email)

    mail(to: assessment.email, subject: "Still on your DSCSA to-do list?")
  end

  private

  def unsubscribe_url_for(email)
    unsubscribe_url(token: EmailUnsubscribeToken.generate(email))
  end

  # The gap to lead with in the day-3 email: prefer one the platform
  # itself closes (a trial converts directly) over one that needs a
  # written process or the compliance-officer retainer. Falls back to
  # whatever gap is first if every gap is platform-solvable or none are.
  PLATFORM_SOLVED_KEYS = %w[custody coldchain records].freeze

  def priority_gap(assessment)
    gaps = assessment.gaps
    gaps.find { |g| PLATFORM_SOLVED_KEYS.include?(g[:key]) } || gaps.first
  end
end
