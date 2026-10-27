module Ops
  # The numbers behind the Monday operator email (OpsDigestMailer): what
  # happened in the last week across the funnel -- leads, readiness checks,
  # signups, trials, paying customers -- plus what's waiting on the
  # operator. Customer-only: orgs flagged internal (Organization.customers)
  # never count. Read-only.
  class WeeklyDigest
    PERIOD = 7.days

    attr_reader :since, :until_time

    def initialize(now: Time.current)
      @until_time = now
      @since = now - PERIOD
    end

    def new_leads
      @new_leads ||= CallRequest.where(created_at: since..until_time).order(:created_at).to_a
    end

    def unhandled_leads_count
      CallRequest.unhandled.count
    end

    def assessments
      @assessments ||= DscsaAssessment.where(created_at: since..until_time)
    end

    def assessments_count = assessments.count
    def assessments_with_email_count = assessments.where.not(email: [ nil, "" ]).count

    def average_score
      avg = assessments.average(:score)
      avg&.round
    end

    def new_organizations
      @new_organizations ||= Organization.customers.where(created_at: since..until_time).order(:created_at).to_a
    end

    def subscriptions_started
      @subscriptions_started ||= customer_subscriptions.where(created_at: since..until_time).includes(:organization).order(:created_at).to_a
    end

    def trialing_count = customer_subscriptions.trialing.count
    def active_count = customer_subscriptions.active.count
    def payment_failing_count = customer_subscriptions.where(status: %w[past_due unpaid]).count

    def canceled_this_week
      customer_subscriptions.canceled.where(updated_at: since..until_time).includes(:organization).to_a
    end

    def free_setups_owed
      Organization.where.not(free_setup_owed_at: nil).where(free_setup_completed_at: nil).order(:free_setup_owed_at).to_a
    end

    def bot_blocks_count
      BotBlock.where(created_at: since..until_time).count
    end

    # A line for the subject: the one number worth seeing in the inbox list.
    def headline
      parts = [ "#{new_leads.size} #{'lead'.pluralize(new_leads.size)}",
                "#{subscriptions_started.size} new #{'subscription'.pluralize(subscriptions_started.size)}" ]
      parts << "#{free_setups_owed.size} setup#{'s' unless free_setups_owed.size == 1} owed" if free_setups_owed.any?
      parts.join(", ")
    end

    private

    def customer_subscriptions
      Subscription.where(organization_id: Organization.customers.select(:id))
    end
  end
end
