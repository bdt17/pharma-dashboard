# The getting-started sequence (sent by OnboardingEmailJob) and the
# trial-ending notice. Each nudge leads with the organization's next
# unfinished "Getting started" step, so it always says one concrete thing
# to do -- the same steps, in the same order, as the Dashboard checklist.
class OnboardingMailer < ApplicationMailer
  STEPS = [
    { key: :vehicle, done: :added_a_vehicle?, title: "Add your delivery vehicle",
      hint: "The van or car the medication rides in. No GPS tracker needed: drivers' phones record location at each handoff.",
      path: :new_vehicle_url },
    { key: :batch, done: :logged_a_batch?, title: "Log your first batch",
      hint: "The lot you're delivering, and who's driving it.",
      path: :new_batch_url },
    { key: :delivery, done: :generated_a_packet?, title: "Record a pickup and delivery",
      hint: "On a phone, open Deliveries and tap Record pickup, then Record delivery to capture the signature. That generates your first Compliance Packet.",
      path: :deliveries_url }
  ].freeze

  # stage: 1, 2 or 3 -- which of OnboardingEmailJob::SCHEDULE this is.
  def nudge(user, stage)
    @user = user
    @organization = user.organization
    @stage = stage
    @step = next_step(@organization)
    @done_count = STEPS.count { |step| @organization.public_send(step[:done]) }
    @step_url = public_send(@step[:path])
    @invite = !@organization.invited_a_teammate?
    @sample_data = SampleData.available?(@organization)
    @free_setup = free_setup_status(@organization)
    @unsubscribe_url = unsubscribe_url_for(user.email)

    mail(to: user.email, subject: nudge_subject)
  end

  def trial_ending(user, subscription)
    @user = user
    @organization = user.organization
    @subscription = subscription
    @ends_on = subscription.current_period_end.to_date
    @plan_name = subscription.plan&.name
    @vehicles = @organization.vehicles.real.count
    @batches = @organization.batches.real.count
    @packets = @organization.compliance_reports.count

    mail(to: user.email, subject: "Your Pharma Transport trial ends #{@ends_on.strftime('%B %-d')}")
  end

  private

  def next_step(organization)
    STEPS.find { |step| !organization.public_send(step[:done]) } || STEPS.last
  end

  # :owed -- they qualified for the DeadlineOffer and the call hasn't
  # happened; :offer -- the offer is running and they haven't started a
  # trial yet; nil -- say nothing about it.
  def free_setup_status(organization)
    return :owed if organization.free_setup_owed_at.present? && organization.free_setup_completed_at.nil?
    return :offer if DeadlineOffer.active? && organization.subscriptions.none?(&:active_or_trialing?)

    nil
  end

  def nudge_subject
    case @stage
    when 1 then "Your first delivery record takes about 10 minutes"
    when 2 then "Next step for #{@organization.name}: #{@step[:title].downcase}"
    else "Want a hand setting up Pharma Transport?"
    end
  end
end
