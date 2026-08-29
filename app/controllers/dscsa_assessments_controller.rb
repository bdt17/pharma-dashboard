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
      redirect_to dscsa_assessment_result_path(@assessment)
    else
      render :new, status: :unprocessable_content
    end
  end

  def result
    @assessment = DscsaAssessment.find_by!(token: params[:token])
  end
end
