# Fires one step of the DSCSA assessment follow-up sequence -- see
# DscsaAssessmentMailer for what each step says. Scheduled twice at
# submission time (DscsaAssessmentsController#create), with `wait: 3.days`
# / `wait: 7.days`, rather than run from a recurring sweep: there's
# nothing to re-check on a cadence, just one delayed send per assessment,
# so a one-shot scheduled job is simpler than a table of "next send due"
# state a sweep would have to scan.
#
# Re-checks state at send time rather than when it was enqueued, since
# days have passed: skips if the assessment or its email is gone, if the
# email unsubscribed in the meantime, or if that email has since become
# a real, subscribed customer (nurturing someone into a trial they
# already started makes no sense, and might as well not still tick a
# "we should tell them to sign up" box for someone who's already in).
class DscsaAssessmentFollowUpJob < ApplicationJob
  queue_as :default

  STEPS = %w[day3 day7].freeze

  def perform(assessment_id, step)
    raise ArgumentError, "unknown step #{step.inspect}" unless STEPS.include?(step)

    assessment = DscsaAssessment.find_by(id: assessment_id)
    return if assessment.blank? || assessment.email.blank?
    return if EmailSuppression.suppressed?(assessment.email)
    return if already_converted?(assessment.email)
    # A day-3 email built around "here's the gap to close" has nothing to
    # say to someone who answered every question "yes" -- skip rather
    # than send an empty or malformed email. day7 doesn't reference gaps.
    return if step == "day3" && assessment.gaps.empty?

    case step
    when "day3" then DscsaAssessmentMailer.follow_up_day3(assessment).deliver_later
    when "day7" then DscsaAssessmentMailer.follow_up_day7(assessment).deliver_later
    end
  end

  private

  def already_converted?(email)
    user = User.find_by(email: email)
    return false unless user

    user.organization.subscriptions.order(created_at: :desc).first&.active_or_trialing? || false
  end
end
