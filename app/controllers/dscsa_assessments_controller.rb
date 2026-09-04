# The public DSCSA readiness self-assessment: a short questionnaire that
# scores how ready a pharmacy is for the enhanced drug distribution
# security requirements once the small-dispenser exemption ends, and points
# each gap at how Pharma Transport (or the compliance-officer retainer)
# closes it. An acquisition funnel -- no account required.
# POST /dscsa-assessment is throttled in config/initializers/rack_attack.rb.
class DscsaAssessmentsController < ApplicationController
  def new
  end

  def create
    @assessment = DscsaAssessment.build_from(params)

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

  private

  # DscsaAssessmentFollowUpJob re-checks EmailSuppression and conversion
  # status itself at send time (days from now), so it's safe to schedule
  # both delayed steps here unconditionally rather than re-deriving that
  # state twice.
  def schedule_follow_up_sequence(assessment)
    DscsaAssessmentMailer.result_email(assessment).deliver_later
    DscsaAssessmentFollowUpJob.set(wait: 3.days).perform_later(assessment.id, "day3")
    DscsaAssessmentFollowUpJob.set(wait: 7.days).perform_later(assessment.id, "day7")
  end
end
