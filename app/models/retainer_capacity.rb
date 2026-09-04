# How full the fractional-compliance-officer retainer is. Not self-serve
# or billed through Stripe -- Brett takes on clients by hand -- so there's
# no natural place in the schema for "how many active clients right now."
# Read from an env var rather than a database row: the whole point of a
# 5-client cap is that it changes slowly, and an env var is something
# Brett can already update himself via Render without a code change or a
# new admin surface built just for one number.
#
# Deliberately does NOT default an unset COMPLIANCE_OFFICER_ACTIVE_CLIENTS
# to anything but 0 -- unset means "show every slot open." That's the
# honest default (never fabricate scarcity), even though it means the
# page shows the wrong count until Brett actually sets the real one.
class RetainerCapacity
  TOTAL_SLOTS = 5

  def self.active_clients
    ENV.fetch("COMPLIANCE_OFFICER_ACTIVE_CLIENTS", "0").to_i.clamp(0, TOTAL_SLOTS)
  end

  def self.slots_available
    TOTAL_SLOTS - active_clients
  end

  def self.full?
    slots_available <= 0
  end
end
