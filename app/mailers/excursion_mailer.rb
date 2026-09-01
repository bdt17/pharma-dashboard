# Cold-chain excursion notifications. Goes to the people in the batch's
# organization who can actually do something about a shipment going warm:
# admins and pharmacists. Falls back to the default sender address only if
# an org somehow has neither (it always has at least one admin in practice).
class ExcursionMailer < ApplicationMailer
  def alert(excursion_event)
    @event = excursion_event
    @batch = excursion_event.batch

    mail(
      to: recipients,
      subject: "Temperature excursion: #{@batch.lot_number} at #{@event.trigger_temp.round(1)}°C"
    )
  end

  def resolved(excursion_event)
    @event = excursion_event
    @batch = excursion_event.batch

    mail(
      to: recipients,
      subject: "Resolved: #{@batch.lot_number} back within 2–8°C"
    )
  end

  private

  def recipients
    emails = @batch.organization.users.where(role: %w[admin pharmacist]).pluck(:email)
    emails.presence || [ self.class.default[:from] ]
  end
end
