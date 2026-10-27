# The public DSCSA readiness self-assessment: a short questionnaire that
# scores how ready a pharmacy is for the enhanced drug distribution
# security requirements once the small-dispenser exemption ends, and points
# each gap at how Pharma Transport (or the compliance-officer retainer)
# closes it. An acquisition funnel -- no account required.
# POST /dscsa-assessment is throttled in config/initializers/rack_attack.rb.
class DscsaAssessmentsController < ApplicationController
  include BotProtection
  protect_from_bots only: :create

  def new
  end

  def create
    @assessment = DscsaAssessment.build_from(params)
    @assessment.utm_source = utm_source
    @assessment.utm_campaign = utm_campaign

    if @assessment.save
      schedule_follow_up_sequence(@assessment) if @assessment.email.present?
      redirect_to dscsa_assessment_result_path(@assessment)
    else
      render :new, status: :unprocessable_content
    end
  end

  def result
    @assessment = DscsaAssessment.find_by!(token: params[:token])
  end

  # The printable readiness report -- same unguessable token as the result
  # page, so anyone with the result link can download it.
  def report
    assessment = DscsaAssessment.find_by!(token: params[:token])
    report = DscsaReadinessReport.new(assessment, result_url: dscsa_assessment_result_url(assessment))

    send_data report.generate, filename: report.filename, type: "application/pdf", disposition: "attachment"
  end

  private

  # There is no result page without a saved assessment, so a bot is sent
  # back to a blank form -- indistinguishable from a validation bounce.
  def pretend_bot_submission_succeeded
    redirect_to dscsa_assessment_path
  end

  def ask_to_resubmit_form
    flash.now[:alert] = BotProtection::RESUBMIT_NOTICE
    render :new, status: :unprocessable_content
  end

  # DscsaAssessmentFollowUpJob re-checks EmailSuppression and conversion
  # status itself at send time (days from now), so it's safe to schedule
  # both delayed steps here unconditionally rather than re-deriving that
  # state twice.
  def schedule_follow_up_sequence(assessment)
    # Someone who unsubscribed gets nothing -- not even the first email --
    # however many times their address is typed into the form.
    return if EmailSuppression.suppressed?(assessment.email)

    DscsaAssessmentMailer.result_email(assessment).deliver_later
    DscsaAssessmentFollowUpJob.set(wait: 3.days).perform_later(assessment.id, "day3")
    DscsaAssessmentFollowUpJob.set(wait: 7.days).perform_later(assessment.id, "day7")
  end
end
